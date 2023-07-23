import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.google.gson.Gson;
import jakarta.mail.BodyPart;
import jakarta.mail.Message;
import jakarta.mail.Multipart;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.eclipse.angus.mail.util.BASE64DecoderStream;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;
import java.util.regex.Pattern;
import java.util.stream.Stream;

@Slf4j
public class EmailUploadedHandler implements RequestHandler<SNSEvent, Void> {
    private final static Pattern EXCEL_TYPE_PATTERN = Pattern.compile("^.*\\.xlsx");
    private final Gson gson = new Gson();
    private final S3Service s3Service = new S3Service();
    private final EmailService emailService = new EmailService();

    private record MailEntry(String source) {}
    private record ActionEntry(String bucketName, String objectKey) {}
    private record ReceiptEntry(ActionEntry action) {}
    private record EmailUploaded(MailEntry mail, ReceiptEntry receipt) {}

    private record DecodedAttachment(byte[] content, String contentType, String fileName) {}

    @SneakyThrows
    private List<DecodedAttachment> getAttachments(InputStream email) {
        List<DecodedAttachment> result = new ArrayList<>();
        Session session = Session.getInstance(new Properties());
        Message message = new MimeMessage(session, email);
        Multipart multipart = (Multipart) message.getContent();
        int parts = multipart.getCount();
        log.info("MIME parts: {}", parts);
        for (int idx = 0; idx < parts; idx++) {
            BodyPart bodyPart = multipart.getBodyPart(idx);
            String disposition = bodyPart.getDisposition();
            if (disposition != null) {
                if (disposition.contains("attachment")) {
                    BASE64DecoderStream decoderStream = (BASE64DecoderStream)bodyPart.getContent();
                    byte[] decodedContent = decoderStream.readAllBytes();
                    String fileName = bodyPart.getFileName();
                    String contentType = bodyPart.getContentType();
                    log.info("Found attachment {} of type {}", fileName, contentType);
                    result.add(new DecodedAttachment(decodedContent, contentType, fileName));
                }
            }
        }
        return result;
    }

    private record CsvResult(String content, String name) {}

    private CsvResult processSheet(Sheet sheet, String fileName) {
        String name = sheet.getSheetName();
        log.info("Processing sheet {} from file {}", name, fileName);
        StringBuilder csvBuilder = new StringBuilder();
        DataFormatter formatter = new DataFormatter();
        for (Row row: sheet) {
            StringBuilder rowBuilder = new StringBuilder();
            Iterator<Cell> iterator = row.cellIterator();
            while (iterator.hasNext()) {
                Cell cell = iterator.next();
                String value = formatter.formatCellValue(cell);
                rowBuilder.append(value);
                if (iterator.hasNext()) {
                    rowBuilder.append(",");
                }
            }
            csvBuilder.append(rowBuilder).append(System.lineSeparator());
        }
        String csvFileName = name + "-" + fileName + ".csv";
        return new CsvResult(csvBuilder.toString(), csvFileName);
    }

    @SneakyThrows
    private Stream<CsvResult> processAttachment(DecodedAttachment attachment) {
        log.info("Processing excel file {}", attachment.fileName());
        Workbook workbook = new XSSFWorkbook(new ByteArrayInputStream(attachment.content()));
        List<CsvResult> results = new ArrayList<>();
        for (Sheet sheet: workbook) {
            results.add(processSheet(sheet, attachment.fileName()));
        }
        return results.stream();
    }

    private static EmailService.EmailAttachment toEmailAttachment(CsvResult result) {
        return new EmailService.EmailAttachment(result.content().getBytes(StandardCharsets.UTF_8),
                "text/csv",
                result.name());
    }

    @Override
    public Void handleRequest(SNSEvent input, Context context) {
        String fromDomain = System.getenv("FROM_DOMAIN");
        input.getRecords().forEach(record -> {
            EmailUploaded emailUploaded = gson.fromJson(record.getSNS().getMessage(), EmailUploaded.class);
            String bucketName = emailUploaded.receipt().action().bucketName();
            String from = emailUploaded.mail().source();
            String bucketKey = emailUploaded.receipt().action().objectKey();
            log.info("Email received from {} saved to {} as {}", from, bucketName, bucketKey);
            InputStream contentStream = s3Service.getObject(bucketName, bucketKey);
            List<EmailService.EmailAttachment> csvContent = getAttachments(contentStream)
                    .stream()
                    .filter(attachment -> EXCEL_TYPE_PATTERN.matcher(attachment.fileName()).matches())
                    .flatMap(this::processAttachment)
                    .map(EmailUploadedHandler::toEmailAttachment)
                    .toList();
            String fromEmail = "excel@" + fromDomain;
            emailService.sendTextEmailWithAttachments(fromEmail,
                    from,
                    "XLSX to CSV conversion result",
                    "Results attached",
                    csvContent);
        });
        return null;
    }
}
