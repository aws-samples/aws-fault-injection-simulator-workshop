import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as iam from '@aws-cdk/aws-iam';
import * as autoscaling from '@aws-cdk/aws-autoscaling';
import * as alb from '@aws-cdk/aws-elasticloadbalancingv2';
import * as log from '@aws-cdk/aws-logs';
import * as cloudwatch from '@aws-cdk/aws-cloudwatch';
import * as mustache from 'mustache';
import * as ssm from '@aws-cdk/aws-ssm';
import * as rds from '@aws-cdk/aws-rds';

// import * as rds from '@aws-cdk/aws-rds';
import * as fs  from 'fs';
import { isMainThread } from 'worker_threads';
import { GroupMetrics } from '@aws-cdk/aws-autoscaling';

export class AsgCdkTestStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Query existing resources - will this work if we pull this into an app?

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    
    // Create ASG

    // Do bad things with security groups because CDK doesn't allow multiple SGs on Launch configs
    const rdsSgId = ssm.StringParameter.fromStringParameterAttributes(this, 'MyValue', {
      parameterName: 'FisWorkshopRdsSgId'
    }).stringValue;
    const rdsSecurityGroup = ec2.SecurityGroup.fromSecurityGroupId(this, 'FisWorkshopRdsSg', rdsSgId);

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
    mySecurityGroup.connections.allowFrom(rdsSecurityGroup,ec2.Port.allTcp())
    rdsSecurityGroup.connections.allowFrom(mySecurityGroup,ec2.Port.allTcp())


    const amazon2 = ec2.MachineImage.fromSSMParameter(
      '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs', 
      ec2.OperatingSystemType.LINUX);

    const instanceRole = new iam.Role(this, 'FisInstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy')
      ],
    });
    instanceRole.addToPrincipalPolicy(new iam.PolicyStatement({
      resources: ['*'], // TODO find a way to query this 
      actions: ['secretsmanager:GetSecretValue'],
      effect: iam.Effect.ALLOW
    }));

    const myASG = new autoscaling.AutoScalingGroup(this, 'ASG', {
      vpc,
      instanceType: new ec2.InstanceType('t3.large'),
      role: instanceRole,
      machineImage: amazon2,
      minCapacity: 1,
      maxCapacity: 3,
      groupMetrics: [autoscaling.GroupMetrics.all()],
      desiredCapacity: 1,
      init: ec2.CloudFormationInit.fromElements(
        ec2.InitFile.fromString('/home/ec2-user/.aws/config',
          `[default]\nregion = ${this.region}\n`, {
          mode: '000600',
          owner: 'ec2-user',
          group: 'ec2-user'
        }),
        ec2.InitFile.fromString(
          '/home/ec2-user/create_db.py', 
          mustache.render(fs.readFileSync('./assets/create_db.py', 'utf8'),{
            auroraSecretArn: 'FisAuroraSecret', //TODO: figure out a way to query this from secretmanager
            mysqlSecretArn: 'FisMysqlSecret', //TODO: figure out a way to query this from secretmanager
          }),          
          {
            mode: '000755',
            owner: 'ec2-user',
            group: 'ec2-user'
            }
        ),
        ec2.InitFile.fromString(
          '/home/ec2-user/test_mysql_connector_curses.py', 
          mustache.render(fs.readFileSync('./assets/test_mysql_connector_curses.py', 'utf8'),{
            auroraSecretArn: 'FisAuroraSecret', //TODO: figure out a way to query this from secretmanager
            mysqlSecretArn: 'FisMysqlSecret', //TODO: figure out a way to query this from secretmanager
          }),          
          {
            mode: '000755',
            owner: 'ec2-user',
            group: 'ec2-user'
            }
        ),
        ec2.InitFile.fromString(
          '/home/ec2-user/test_pymysql_curses.py', 
          mustache.render(fs.readFileSync('./assets/test_pymysql_curses.py', 'utf8'),{
            auroraSecretArn: 'FisAuroraSecret', //TODO: figure out a way to query this from secretmanager
            mysqlSecretArn: 'FisMysqlSecret', //TODO: figure out a way to query this from secretmanager
          }),          
          {
            mode: '000755',
            owner: 'ec2-user',
            group: 'ec2-user'
            }
        ),
        ec2.InitFile.fromString(
          '/opt/aws/amazon-cloudwatch-agent/bin/config.json', 
          mustache.render(fs.readFileSync('./assets/cwagent-config.json', 'utf8'),{
            accessLogPath: "/fis-workshop"
          }),          
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
        ec2.InitFile.fromAsset(
          '/etc/nginx/nginx.conf', 
          './assets/nginx-config.conf', 
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

    // UserData DOES replace ${} style variables!!! Handle with care
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

    const lbUrl = new cdk.CfnOutput(this, 'FisAsgUrl', {value: lb.loadBalancerDnsName});

    // Set up logs, metrics, and dashboards

    const logGroupNginxAccess = new log.LogGroup(this, 'FisLogGroupNginxAccess', {
      logGroupName: '/fis-workshop/asg-access-log',
      retention: log.RetentionDays.ONE_WEEK,
    });
    
    [2,4,5].forEach(element => {
      new log.MetricFilter(this, 'NginxMetricsFilter' + element + 'xx', {
        logGroup: logGroupNginxAccess,
        metricNamespace: 'fisworkshop',
        metricName: element + 'xx',
        filterPattern: log.FilterPattern.stringValue('$.status','=',element + '*'),
        metricValue: '1',
        defaultValue: 0
      });        
    });

    new log.MetricFilter(this, 'NginxMetricsFilterDuration', {
      logGroup: logGroupNginxAccess,
      metricNamespace: 'fisworkshop',
      metricName: 'duration',
      filterPattern: log.FilterPattern.numberValue('$.request_time','>=',0),
      metricValue: '$.request_time',
      defaultValue: 0
    });        

    const logGroupNginxError = new log.LogGroup(this, 'FisLogGroupNginxError', {
      logGroupName: '/fis-workshop/asg-error-log',
      retention: log.RetentionDays.ONE_WEEK,
    });


    const asgDashboard = new cloudwatch.Dashboard(this,'FisAsgDashboard', {
      dashboardName: 'FisAsgDashboard'
    });

    const raw2xx = new cloudwatch.Metric({
      label: "2xx",
      period: cdk.Duration.seconds(1),
      unit: cloudwatch.Unit.PERCENT,
      namespace: 'fisworkshop',
      metricName: '2xx',  
      color: cloudwatch.Color.GREEN,
    });
    const raw5xx = new cloudwatch.Metric({
      label: "5xx",
      period: cdk.Duration.seconds(1),
      unit: cloudwatch.Unit.PERCENT,
      namespace: 'fisworkshop',
      metricName: '5xx',  
      color: cloudwatch.Color.RED
    });

    asgDashboard.addWidgets(new cloudwatch.GraphWidget({
      title: "First",
      left: [raw2xx],

    }));

    
    // Escape hatch does not replace ${} style variables, use Mustache instead
    const manualDashboard = new cdk.CfnResource(this, 'AsgDashboardEscapeHatch', {
      type: 'AWS::CloudWatch::Dashboard',
      properties: {
        DashboardName: 'FisDashboard-'+this.region,
        DashboardBody: mustache.render(fs.readFileSync('./assets/dashboard-asg.json', 'utf8'),{
          region: this.region,
          asgName: myASG.autoScalingGroupName
        })
      }
    });

  }
}
