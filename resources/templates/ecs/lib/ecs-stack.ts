import * as cdk from "@aws-cdk/core";
import ec2 = require("@aws-cdk/aws-ec2");
import * as ecs from "@aws-cdk/aws-ecs";
import * as ecs_patterns from "@aws-cdk/aws-ecs-patterns";
import * as autoscaling from "@aws-cdk/aws-autoscaling";

export class EcsStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const cluster = new ecs.Cluster(this, "Cluster", {
    });

    const asg = new autoscaling.AutoScalingGroup(this, "EcsAsgProvider", {
      vpc: cluster.vpc,
      instanceType: new ec2.InstanceType("t3.medium"),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),
      desiredCapacity: 1
    });

    cluster.addAsgCapacityProvider(
      new ecs.AsgCapacityProvider(this, "CapacityProvider", {
        autoScalingGroup: asg,
        capacityProviderName: "fisWorkshopCapacityProvider"
      })
    );

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
  }
}
