import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.google.gson.Gson;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class EmailUploadedHandler implements RequestHandler<SNSEvent, Void> {
    private final Gson gson = new Gson();

    private record MailEntry(String source) {}
    private record ActionEntry(String bucketName, String objectKey) {}
    private record ReceiptEntry(ActionEntry action) {}
    private record EmailUploaded(MailEntry mail, ReceiptEntry receipt) {}

    @Override
    public Void handleRequest(SNSEvent input, Context context) {
        input.getRecords().forEach(record -> {
            EmailUploaded emailUploaded = gson.fromJson(record.getSNS().getMessage(), EmailUploaded.class);
            String bucketName = emailUploaded.receipt().action().bucketName();
            String from = emailUploaded.mail().source();
            String bucketKey = emailUploaded.receipt().action().objectKey();
            log.info("Email received from {} saved to {} as {}", from, bucketName, bucketKey);
        });
        return null;
    }
}
