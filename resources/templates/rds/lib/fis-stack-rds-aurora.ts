import * as cdk            from 'aws-cdk-lib';
import {Construct}         from 'constructs';
import * as ec2            from 'aws-cdk-lib/aws-ec2';
import * as rds            from 'aws-cdk-lib/aws-rds';
import { InstanceType }    from 'aws-cdk-lib/aws-ec2';
import * as ssm            from 'aws-cdk-lib/aws-ssm';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

export class FisStackRdsAurora extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    

    const rdsSecurityGroup = new ec2.SecurityGroup(this, 'rdsSecurityGroup', {
      vpc,
      securityGroupName: "FisRdsSecurityGroup",
      description: 'Allow mysql access to RDS',
      allowAllOutbound: true   // Can be set to false
    });    
    rdsSecurityGroup.connections.allowFrom(rdsSecurityGroup, ec2.Port.tcp(3306), 'allow mysql access from self');



    const auroraCredentials = rds.Credentials.fromGeneratedSecret('clusteradmin', { secretName: "FisAuroraSecret"});
    const aurora = new rds.DatabaseCluster(this, 'FisWorkshopRdsAurora', {
      engine: rds.DatabaseClusterEngine.auroraMysql({ 
        version: rds.AuroraMysqlEngineVersion.VER_2_10_2
      }),
      credentials: auroraCredentials,
      defaultDatabaseName: 'testdb',
      instanceProps: {
        vpcSubnets: {
          subnetType: ec2.SubnetType.PRIVATE,
        },
        vpc,
        securityGroups: [rdsSecurityGroup],
      },
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // based on https://bobbyhadz.com/blog/aws-cdk-rds-example
    const mysqlCredentials = rds.Credentials.fromGeneratedSecret('clusteradmin', { secretName: "FisMysqlSecret"});
    const mysql = new rds.DatabaseInstance(this,"FisWorkshopRdsMySql",{
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE,
      },
      // engine: rds.DatabaseInstanceEngine.postgres({
      //   version: rds.PostgresEngineVersion.VER_13_1,
      // }),
      engine: rds.DatabaseInstanceEngine.mysql({
        version: rds.MysqlEngineVersion.VER_5_7,
      }),
      credentials: mysqlCredentials,
      databaseName: 'testdb',
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.BURSTABLE3,
        ec2.InstanceSize.MICRO,
      ),
      multiAz: true,
      securityGroups: [rdsSecurityGroup],
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });
    
    // Store things in SSM so we can coordinate multiple stacks
    const rdsSecurityGroupParam = new ssm.StringParameter(this, 'FisWorkshopRdsSgId', {
      parameterName: 'FisWorkshopRdsSgId',
      stringValue: rdsSecurityGroup.securityGroupId
    });
    const rdsAuroraSecretArn = new ssm.StringParameter(this, 'FisWorkshopAuroraSecretArn', {
      parameterName: 'FisWorkshopAuroraSecretArn',
      stringValue: aurora.secret?.secretFullArn ? aurora.secret?.secretFullArn : "UNDEFINED" 
    });
    const rdsMysqlSecretArn = new ssm.StringParameter(this, 'FisWorkshopMysqlSecretArn', {
      parameterName: 'FisWorkshopMysqlSecretArn',
      stringValue: mysql.secret?.secretFullArn ? mysql.secret?.secretFullArn : "UNDEFINED" 
    });

    // Expose values to workshop users
    const auroraHostName = new cdk.CfnOutput(this, 'FisAuroraHostName', {value: aurora.clusterEndpoint.hostname});
    const mysqlHostName = new cdk.CfnOutput(this, 'FisMysqlHostName', {value: mysql.dbInstanceEndpointAddress});
    // const securityGroupParam = new cdk.CfnOutput(this, 'FisRdsSgParam', {value: rdsSecurityGroupParam.stringValue});

    const auroraSecret = new cdk.CfnOutput(this,"FisAuroraSecret", {value: aurora.secret?.secretFullArn ? aurora.secret?.secretFullArn : "UNDEFINED" })
    const mysqlSecret = new cdk.CfnOutput(this,"FisMysqlSecret", {value: mysql.secret?.secretFullArn ? mysql.secret?.secretFullArn : "UNDEFINED" })

    // const retrieveMysqlSecret = secretsmanager.Secret.f fromSecretAttributes(this,"FisAuroraSecret2",{ secretCompleteArn: aurora.secret?.secretFullArn } );
    // // retrieveMysqlSecret.secretValueFromJson()
    // const auroraLookup = new cdk.CfnOutput(this,"auroraLookup", {value: retrieveMysqlSecret.secretValueFromJson("host").toString()})
  }
}
