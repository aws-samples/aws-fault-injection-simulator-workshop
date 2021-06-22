import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as rds from '@aws-cdk/aws-rds';
import { InstanceType } from '@aws-cdk/aws-ec2';
import * as ssm from '@aws-cdk/aws-ssm';

export class FisStackRdsAurora extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    
    const credentials = rds.Credentials.fromGeneratedSecret('clusteradmin');

    const rdsSecurityGroup = new ec2.SecurityGroup(this, 'rdsSecurityGroup', {
      vpc,
      securityGroupName: "FisRdsSecurityGroup",
      description: 'Allow mysql access to RDS',
      allowAllOutbound: true   // Can be set to false
    });    
    rdsSecurityGroup.connections.allowFrom(rdsSecurityGroup, ec2.Port.tcp(3306), 'allow mysql access from self');
    const rdsSecurityGroupParam = new ssm.StringParameter(this, 'FisWorkshopRdsSgId', {
      parameterName: 'FisWorkshopRdsSgId',
      stringValue: rdsSecurityGroup.securityGroupId
    });



    const aurora = new rds.DatabaseCluster(this, 'FisWorkshopRdsAurora', {
      engine: rds.DatabaseClusterEngine.auroraMysql({ 
        version: rds.AuroraMysqlEngineVersion.VER_5_7_12 
      }),
      credentials: credentials,
      instanceProps: {
        vpcSubnets: {
          subnetType: ec2.SubnetType.PRIVATE,
        },
        vpc,
        securityGroups: [rdsSecurityGroup]
      },
    });

    // based on https://bobbyhadz.com/blog/aws-cdk-rds-example
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
      credentials: credentials,
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.BURSTABLE3,
        ec2.InstanceSize.MICRO,
      ),
      multiAz: true,
      securityGroups: [rdsSecurityGroup]
    });

    const auroraConnectionString = new cdk.CfnOutput(this, 'FisAuroraConnectionString', {value: aurora.clusterEndpoint.hostname});
    const mysqlConnectionString = new cdk.CfnOutput(this, 'FisMysqlConnectionString', {value: mysql.dbInstanceEndpointAddress});
    const securityGroupParam = new cdk.CfnOutput(this, 'FisRdsSgParam', {value: rdsSecurityGroupParam.stringValue});
  }
}
