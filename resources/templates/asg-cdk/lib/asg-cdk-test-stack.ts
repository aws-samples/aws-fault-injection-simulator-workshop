import * as cdk         from 'aws-cdk-lib';
import {Duration, Stack}          from 'aws-cdk-lib';
import {Construct}      from 'constructs';
import * as ec2         from 'aws-cdk-lib/aws-ec2';
import * as iam         from 'aws-cdk-lib/aws-iam';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as alb         from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as log         from 'aws-cdk-lib/aws-logs';
import * as cloudwatch  from 'aws-cdk-lib/aws-cloudwatch';
import * as cwactions   from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ssm         from 'aws-cdk-lib/aws-ssm';

import * as mustache    from 'mustache';
import * as fs  from 'fs';
import { ApplicationProtocol } from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Protocol } from 'aws-cdk-lib/aws-ec2';

export class AsgCdkTestStack extends Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Set some constants for convenience

    const fisLogGroup = '/fis-workshop/fis-logs';
    const nginxAccessLogGroup = '/fis-workshop/asg-access-log';
    const nginxErrorLogGroup = '/fis-workshop/asg-error-log';
    
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


    const amazon2 = ec2.MachineImage.fromSsmParameter(
      '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs', 
      { os: ec2.OperatingSystemType.LINUX }
      );

    const instanceRole = new iam.Role(this, 'FisInstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy')
      ],
    });
    instanceRole.addToPrincipalPolicy(new iam.PolicyStatement({
      resources: ['*'], // TODO find a way to query this 
      actions: [
        'secretsmanager:GetSecretValue',
        'cloudformation:DescribeStacks'
      ],
      effect: iam.Effect.ALLOW
    }));

    const myASG = new autoscaling.AutoScalingGroup(this, 'ASG', {
      vpc,
      instanceType: new ec2.InstanceType('t2.micro'),
      role: instanceRole,
      machineImage: amazon2,
      minCapacity: 1,
      maxCapacity: 9,
      // // This is tempting for NACL tests but it breaks things really badly
      // healthCheck: autoscaling.HealthCheck.elb({grace: cdk.Duration.seconds(180)}),
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
            nginxAccessLogGroup,
            nginxErrorLogGroup
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

    // This works but doesn't expose alarms for introspection
    // Moving to explicit alarm based scaling instead
    //
    // myASG.scaleOnCpuUtilization('KeepSpareCPU', {
    //   targetUtilizationPercent: 50,
    //   cooldown: cdk.Duration.minutes(1)
    // });

    // This works but doesn't allow asymmetric timing
    //
    // myASG.scaleOnMetric('ScaleOnCpu', {
    //   metric: myAsgCpuMetric,
    //   evaluationPeriods: 1,
    //   scalingSteps: [
    //     { upper: 90, change: +1 },
    //     { lower: 20, change: -1 }
    //   ]
    // });

    // This is a bit convoluted in comparison to CFN but at least
    // exposes the same controls
    
    const myAsgCpuMetric = new cloudwatch.Metric({
      namespace: 'AWS/EC2',
      metricName: 'CPUUtilization',
      dimensionsMap: { 
        'AutoScalingGroupName': myASG.autoScalingGroupName
      },
      period: cdk.Duration.minutes(1) 
    });

    const myAsgCpuAlarmHigh = new cloudwatch.Alarm(this, 'FisAsgHighCpuAlarm', {
      metric: myAsgCpuMetric,
      threshold: 90.0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
      evaluationPeriods: 1,
      // datapointsToAlarm: 1,
    });

    const myAsgCpuAlarmLow = new cloudwatch.Alarm(this, 'FisAsgLowCpuAlarm', {
      metric: myAsgCpuMetric,
      threshold: 20.0,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_OR_EQUAL_TO_THRESHOLD,
      evaluationPeriods: 3,
      // datapointsToAlarm: 2,
    });

    const myAsgManualScalingActionUp = new autoscaling.StepScalingAction(this,"ScaleUp", {
      autoScalingGroup: myASG,
      adjustmentType: autoscaling.AdjustmentType.CHANGE_IN_CAPACITY,
      // cooldown: cdk.Duration.minutes(1)
    });
    myAsgManualScalingActionUp.addAdjustment({
      adjustment: 1,
      lowerBound: 0,
      // upperBound: 100
    });
    myAsgCpuAlarmHigh.addAlarmAction(new cwactions.AutoScalingAction(myAsgManualScalingActionUp))

    const myAsgManualScalingActionDown = new autoscaling.StepScalingAction(this,"ScaleDown", {
      autoScalingGroup: myASG,
      adjustmentType: autoscaling.AdjustmentType.CHANGE_IN_CAPACITY,
      // cooldown: cdk.Duration.minutes(1)
    });
    myAsgManualScalingActionDown.addAdjustment({
      adjustment: -1,
      upperBound: 0,
      // lowerBound: -100
    });
    myAsgCpuAlarmLow.addAlarmAction(new cwactions.AutoScalingAction(myAsgManualScalingActionDown))


    const lb = new alb.ApplicationLoadBalancer(this, 'FisAsgLb', {
      vpc,
      internetFacing: true
    });

    const listener = lb.addListener('FisAsgListener', {
      port: 80,

    
    });

    const tg1 = new alb.ApplicationTargetGroup(this, 'FisAsgTargetGroup', {
      targetType: alb.TargetType.INSTANCE,
      port: 80,
      targets: [myASG],
      vpc,
      healthCheck: {
        healthyHttpCodes: '200-299',
        healthyThresholdCount: 2,
        interval: Duration.seconds(20),
        timeout: Duration.seconds(15),
        unhealthyThresholdCount: 10,
        path: '/'
      }
    });

    listener.addTargetGroups('FisTargetGroup',{
      targetGroups: [tg1],
    });

    listener.connections.allowDefaultPortFromAnyIpv4('Open to the world');

    

    const lbUrl = new cdk.CfnOutput(this, 'FisAsgUrl', {value: 'http://' + lb.loadBalancerDnsName});

    // Set up logs, metrics, and dashboards

    const logGroupFisLogs = new log.LogGroup(this, 'FisLogGroupFisLogs', {
      logGroupName: fisLogGroup,
      retention: log.RetentionDays.ONE_WEEK,
    });

    const outputFisLog = new cdk.CfnOutput(this, 'FisLogsArn', {value: logGroupFisLogs.logGroupArn});

    const logGroupNginxAccess = new log.LogGroup(this, 'FisLogGroupNginxAccess', {
      logGroupName: nginxAccessLogGroup,
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
      logGroupName: nginxErrorLogGroup,
      retention: log.RetentionDays.ONE_WEEK,
    });
    
    // Escape hatch does not replace ${} style variables, use Mustache instead
    const manualDashboard = new cdk.CfnResource(this, 'AsgDashboardEscapeHatch', {
      type: 'AWS::CloudWatch::Dashboard',
      properties: {
        DashboardName: 'FisDashboard-'+this.region,
        DashboardBody: mustache.render(fs.readFileSync('./assets/dashboard-asg.json', 'utf8'),{
          region: this.region,
          asgName: myASG.autoScalingGroupName,
          lbName: lb.loadBalancerFullName,
          targetgroupName: tg1.targetGroupFullName,
        })
      }
    });

  }
}