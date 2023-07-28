import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.GetItemRequest;
import software.amazon.awssdk.services.dynamodb.model.GetItemResponse;

@Slf4j
public class BlockingRuleHandler implements RequestHandler<SESEvent.Event, SESLambdaResponse> {

  private final DynamoDbClient dynamoDbClient = DynamoDbClient.create();

  @Override
  public SESLambdaResponse handleRequest(SESEvent.Event input, Context context) {
    String blockedEmailsTable = System.getenv("BLOCKED_EMAILS_TABLE");
    SESEvent.Record record = input.Records().get(0);
    String sender = record.ses().mail().source();
    log.info("Received email from {}, checking deny list", sender);
    GetItemResponse response =
        dynamoDbClient.getItem(
            GetItemRequest.builder()
                .tableName(blockedEmailsTable)
                .key(Map.of("email", AttributeValue.fromS(sender)))
                .build());
    if (response.hasItem()) {
      log.info("Email {} fond on deny list", sender);
      return SESLambdaResponse.stopRule();
    }
    log.info("Email {} allowed", sender);
    return SESLambdaResponse.continueRule();
  }
}
