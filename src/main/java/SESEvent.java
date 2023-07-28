import java.util.List;

public interface SESEvent {
  record Mail(String source) {}

  record Ses(Mail mail) {}

  record Record(Ses ses) {}

  record Event(List<Record> Records) {}
}
