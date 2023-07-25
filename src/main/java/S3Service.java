import java.io.InputStream;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

public class S3Service {
  private final S3Client s3Client = S3Client.create();

  public InputStream getObject(String bucket, String key) {
    GetObjectRequest request = GetObjectRequest.builder().bucket(bucket).key(key).build();
    return s3Client.getObject(request);
  }
}
