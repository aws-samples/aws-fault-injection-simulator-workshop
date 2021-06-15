import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as iam from '@aws-cdk/aws-iam';
import * as autoscaling from '@aws-cdk/aws-autoscaling';
import * as alb from '@aws-cdk/aws-elasticloadbalancingv2';

// import * as rds from '@aws-cdk/aws-rds';
import * as fs  from 'fs';
import { isMainThread } from 'worker_threads';

export class AsgCdkTestStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    
    const mySecurityGroup = new ec2.SecurityGroup(this, 'SecurityGroup', {
      vpc,
      description: 'Allow HTTP access to ec2 instances',
      allowAllOutbound: true   // Can be set to false
    });    
    mySecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(), 
      ec2.Port.tcp(80), 
      'allow http access from the world'
    );

    const amazon2 = ec2.MachineImage.fromSSMParameter(
      '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs', 
      ec2.OperatingSystemType.LINUX);

    const instanceRole = new iam.Role(this, 'FisInstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy')
      ]
    });

    const myASG = new autoscaling.AutoScalingGroup(this, 'ASG', {
      vpc,
      instanceType: new ec2.InstanceType('t3.large'),
      role: instanceRole,
      machineImage: amazon2,
      minCapacity: 1,
      maxCapacity: 1,
      desiredCapacity: 1,
      init: ec2.CloudFormationInit.fromElements(
        ec2.InitFile.fromAsset(
          '/opt/aws/amazon-cloudwatch-agent/bin/config.json', 
          './assets/config.json', 
          {
            mode: '000644',
            owner: 'root',
            group: 'root'
          }
        ),
        ec2.InitFile.fromAsset(
          '/usr/share/nginx/html/phpinfo.php', 
          './assets/phpinfo.php', 
          {
            mode: '000644',
            owner: 'root',
            group: 'root'
          }
        ),
        ec2.InitFile.fromAsset(
          '/usr/share/nginx/html/pi.php', 
          './assets/pi.php', 
          {
            mode: '000644',
            owner: 'root',
            group: 'root'
          }
        ),
        ec2.InitFile.fromString('/etc/cfn/cfn-hup.conf',
          `[main]\nstack=${this.stackId}\nregion=${this.region}\n`, {
          mode: '000644',
          owner: 'root',
          group: 'root'
        })
      ),
      signals: autoscaling.Signals.waitForAll({
        timeout: cdk.Duration.minutes(10),
      }),
      securityGroup: mySecurityGroup,
    });

    const userDataScript = fs.readFileSync('./assets/user-data.sh', 'utf8');
    myASG.addUserData(userDataScript);

    const lb = new alb.ApplicationLoadBalancer(this, 'FisAsgLb', {
      vpc,
      internetFacing: true
    });

    const listener = lb.addListener('FisAsgListener', {
      port: 80,
    });

    listener.addTargets('FisAsgTargets', {
      port: 80,
      targets: [myASG]
    });

    listener.connections.allowDefaultPortFromAnyIpv4('Open to the world');
  }
}
