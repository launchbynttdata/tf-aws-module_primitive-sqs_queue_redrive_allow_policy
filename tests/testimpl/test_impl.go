package testimpl

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	awscfg "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	sqstypes "github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type redriveAllowPolicy struct {
	RedrivePermission string   `json:"redrivePermission"`
	SourceQueueArns   []string `json:"sourceQueueArns"`
}

func TestComposableComplete(t *testing.T, ctx types.TestContext) {
	t.Run("VerifyRedriveAllowPolicyKMSAndSend", func(t *testing.T) {
		verifyRedriveAllowPolicyExample(t, ctx, true)
	})
}

func TestComposableCompleteReadonly(t *testing.T, ctx types.TestContext) {
	t.Run("VerifyRedriveAllowPolicyAndKMS", func(t *testing.T) {
		verifyRedriveAllowPolicyExample(t, ctx, false)
	})
}

func verifyRedriveAllowPolicyExample(t *testing.T, ctx types.TestContext, sendProbeMessage bool) {
	t.Helper()

	opts := ctx.TerratestTerraformOptions()
	region := terraform.Output(t, opts, "aws_region")
	require.NotEmpty(t, region, "aws_region output must match the provider region used to create the queues")

	cfg, err := awscfg.LoadDefaultConfig(context.Background(), awscfg.WithRegion(region))
	require.NoError(t, err)
	client := sqs.NewFromConfig(cfg)

	dlqURL := terraform.Output(t, opts, "dlq_url")
	sourceURL := terraform.Output(t, opts, "source_queue_url")
	sourceARN := terraform.Output(t, opts, "source_queue_arn")
	sseMode := terraform.Output(t, opts, "sqs_server_side_encryption")
	moduleID := terraform.Output(t, opts, "id")

	assert.Equal(t, dlqURL, moduleID, "module id should match DLQ URL")
	require.Contains(t, []string{"customer_managed_kms", "sqs_managed"}, sseMode, "unexpected sqs_server_side_encryption value")

	dlqOut, err := client.GetQueueAttributes(context.Background(), &sqs.GetQueueAttributesInput{
		QueueUrl: aws.String(dlqURL),
		AttributeNames: []sqstypes.QueueAttributeName{
			sqstypes.QueueAttributeNameRedriveAllowPolicy,
		},
	})
	require.NoError(t, err)
	actualPolicyJSON, ok := dlqOut.Attributes[string(sqstypes.QueueAttributeNameRedriveAllowPolicy)]
	require.True(t, ok, "RedriveAllowPolicy must be present on DLQ")

	var actualPolicy redriveAllowPolicy
	require.NoError(t, json.Unmarshal([]byte(actualPolicyJSON), &actualPolicy))
	expectedPolicy := redriveAllowPolicy{
		RedrivePermission: "byQueue",
		SourceQueueArns:   []string{sourceARN},
	}
	assert.Equal(t, expectedPolicy, actualPolicy, "redrive allow policy must match source queue ARN from Terraform (independent of primitive module output)")

	for _, url := range []string{dlqURL, sourceURL} {
		var attrNames []sqstypes.QueueAttributeName
		switch sseMode {
		case "customer_managed_kms":
			attrNames = []sqstypes.QueueAttributeName{sqstypes.QueueAttributeNameKmsMasterKeyId}
		case "sqs_managed":
			attrNames = []sqstypes.QueueAttributeName{sqstypes.QueueAttributeNameSqsManagedSseEnabled}
		}

		qOut, err := client.GetQueueAttributes(context.Background(), &sqs.GetQueueAttributesInput{
			QueueUrl:       aws.String(url),
			AttributeNames: attrNames,
		})
		require.NoError(t, err)

		switch sseMode {
		case "customer_managed_kms":
			keyAttr, ok := qOut.Attributes[string(sqstypes.QueueAttributeNameKmsMasterKeyId)]
			require.True(t, ok, "KmsMasterKeyId must be present for CMK-encrypted queue %s", url)
			kmsKeyID := terraform.Output(t, opts, "kms_key_id")
			require.NotEmpty(t, kmsKeyID, "kms_key_id must be set when using customer_managed_kms")
			assert.Equal(t, kmsKeyID, keyAttr, "KMS key should match Terraform output")
		case "sqs_managed":
			sseAttr, ok := qOut.Attributes[string(sqstypes.QueueAttributeNameSqsManagedSseEnabled)]
			require.True(t, ok, "SqsManagedSseEnabled must be present for SQS-managed SSE on queue %s", url)
			assert.Equal(t, "true", sseAttr, "SQS-managed SSE should be enabled")
		}
	}

	if sendProbeMessage {
		_, err := client.SendMessage(context.Background(), &sqs.SendMessageInput{
			QueueUrl:    aws.String(sourceURL),
			MessageBody: aws.String("terratest-sqs-redrive-allow-policy-probe"),
		})
		require.NoError(t, err)
	}
}
