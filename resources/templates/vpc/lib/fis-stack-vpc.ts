import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { IVpc } from 'aws-cdk-lib/aws-ec2';
import * as cdk from 'aws-cdk-lib';

export class FisStackVpc extends cdk.Stack {
  public vpc: IVpc;

  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);


    this.vpc = new ec2.Vpc(this, 'FisVpc', {
      cidr: "10.0.0.0/16",
      maxAzs: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: "FisPub",
          subnetType: ec2.SubnetType.PUBLIC
        },
        {
          cidrMask: 24,
          name: "FisPriv",
          subnetType: ec2.SubnetType.PRIVATE_WITH_NAT
        },
        {
          cidrMask: 24,
          name: "FisIso",
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED
        },
      ]
    });

    new cdk.CfnOutput(this, 'FisVpcId', { value: this.vpc.vpcId });
    
    this.vpc.selectSubnets({ subnetType: ec2.SubnetType.PUBLIC }).subnets.map((subnet, index) => {
      new cdk.CfnOutput(this, 'FisPub' + (index + 1), { value: subnet.subnetId });
    });
    this.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_WITH_NAT }).subnets.map((subnet, index) => {
      new cdk.CfnOutput(this, 'FisPriv' + (index + 1), { value: subnet.subnetId });
    });
    this.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_ISOLATED }).subnets.map((subnet, index) => {
      new cdk.CfnOutput(this, 'FisIso' + (index + 1), { value: subnet.subnetId });
    });



  }
}
