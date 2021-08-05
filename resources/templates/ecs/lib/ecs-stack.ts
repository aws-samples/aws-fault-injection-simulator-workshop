import * as cdk from "@aws-cdk/core";
import ec2 = require("@aws-cdk/aws-ec2");
import * as ecs from "@aws-cdk/aws-ecs";
import * as ecs_patterns from "@aws-cdk/aws-ecs-patterns";
import * as autoscaling from "@aws-cdk/aws-autoscaling";
import * as iam from "@aws-cdk/aws-iam";

export class EcsStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });

    const cluster = new ecs.Cluster(this, "Cluster", {
      vpc: vpc
    });

    const asg = new autoscaling.AutoScalingGroup(this, "EcsAsgProvider", {
      vpc: vpc,
      instanceType: new ec2.InstanceType("t3.medium"),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),
      desiredCapacity: 1
    });

    cluster.addAsgCapacityProvider(
      new ecs.AsgCapacityProvider(this, "CapacityProvider", {
        autoScalingGroup: asg,
        capacityProviderName: "fisWorkshopCapacityProvider",
        enableManagedTerminationProtection: false
      })
    );

    // Add SSM access policy to nodegroup
    asg.role.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonSSMManagedInstanceCore"));

    const taskDefinition = new ecs.Ec2TaskDefinition(this, "SampleAppTaskDefinition", {
    });
    
    taskDefinition.addContainer("SampleAppContainer", {
      image: ecs.ContainerImage.fromRegistry("amazon/amazon-ecs-sample"),
      memoryLimitMiB: 256,
      portMappings: [
        {
          containerPort: 80,
          hostPort: 80
        }
      ]
    });

    const sampleAppService = new ecs_patterns.ApplicationLoadBalancedEc2Service(this, "SampleAppService", {
      cluster: cluster,
      cpu: 256,
      desiredCount: 1,
      memoryLimitMiB: 512,
      taskDefinition: taskDefinition
    });

    asg.attachToApplicationTargetGroup(sampleAppService.targetGroup);

    const ecsUrl = new cdk.CfnOutput(this, 'FisEcsUrl', {value: 'http://' + sampleAppService.loadBalancer.loadBalancerDnsName});
  }
}
