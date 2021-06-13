import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as rds from '@aws-cdk/aws-rds';

export class FisStackRdsAurora extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    // const vpc = new cdk.aws_ec2.Vpc(this, 'TheVPC', {
    //    cidr: "10.120.0.0/16"
    // })
    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    
    const cluster = new rds.DatabaseCluster(this, 'FisWorkshopRdsAurora', {
      // engine: rds.DatabaseClusterEngine.auroraPostgres({ 
      //   version: rds.AuroraPostgresEngineVersion.VER_11_9 
      // }),
      engine: rds.DatabaseClusterEngine.auroraMysql({ 
        version: rds.AuroraMysqlEngineVersion.VER_5_7_12 
      }),
      credentials: rds.Credentials.fromGeneratedSecret('clusteradmin'),
      instanceProps: {
        vpcSubnets: {
          subnetType: ec2.SubnetType.PRIVATE,
        },
        vpc,
      },
    });
  }
}
