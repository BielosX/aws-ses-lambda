import { PolicyStatement, ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import { EmailIdentity, Identity, ReceiptRuleSet } from 'aws-cdk-lib/aws-ses';
import { Sns } from 'aws-cdk-lib/aws-ses-actions';
import { Topic } from 'aws-cdk-lib/aws-sns';
import { Construct } from 'constructs';

type SesConstructProps = {
    domain: string,
    sandboxToEmail: string
};

export class SesConstruct extends Construct {
    public readonly helpEmailReceivedTopic: Topic;
    constructor(scope: Construct, id: string, props: SesConstructProps) {
        super(scope, id);
        new EmailIdentity(this, 'DomainIdentity', {
            identity: Identity.domain(props.domain)
        });
        new EmailIdentity(this, 'SandboxToIdentity', {
            identity: Identity.email(props.sandboxToEmail)
        });
        this.helpEmailReceivedTopic = new Topic(this, 'EmailReceivedTopic');
        this.helpEmailReceivedTopic.grantPublish(new ServicePrincipal('ses.amazonaws.com'));
        new ReceiptRuleSet(this, 'RuleSet', {
            rules: [
                {
                    recipients: [`help@${props.domain}`],
                    actions: [
                        new Sns({
                            topic: this.helpEmailReceivedTopic
                        })
                    ]
                }
            ]
        });
    }
}