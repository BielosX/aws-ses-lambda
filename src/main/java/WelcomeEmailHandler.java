import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.google.gson.Gson;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class WelcomeEmailHandler
    implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {
  private static final String TEMPLATE = "welcome";
  private static final String SUBJECT = "Welcome";
  private final EmailTemplateEngine engine = new EmailTemplateEngine();
  private final EmailService emailService = new EmailService();
  private final Gson gson = new Gson();

  @Override
  public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent input, Context context) {
    String fromDomain = System.getenv("FROM_DOMAIN");
    String fromAddress = "info@" + fromDomain;
    log.info("Received request with body: {}", input.getBody());
    String decodedBody =
        new String(Base64.getDecoder().decode(input.getBody()), StandardCharsets.UTF_8);
    log.info("Decoded body: {}", decodedBody);
    WelcomeEmailRequest request = gson.fromJson(decodedBody, WelcomeEmailRequest.class);
    String emailBody = engine.process(TEMPLATE, input);
    log.info("Sending welcome email to {}", request.email());
    emailService.sendEmail(fromAddress, request.email(), SUBJECT, emailBody);
    return APIGatewayV2HTTPResponse.builder()
        .withStatusCode(200)
        .withBody("Email sent to " + request.email())
        .build();
  }
}
