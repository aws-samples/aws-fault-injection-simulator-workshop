import * as cdk from 'aws-cdk-lib';
import {Construct}         from 'constructs';
import * as ec2            from 'aws-cdk-lib/aws-ec2';
import * as eks            from 'aws-cdk-lib/aws-eks';
import * as iam            from 'aws-cdk-lib/aws-iam';
import * as lambda         from 'aws-cdk-lib/aws-lambda';
import * as logs           from 'aws-cdk-lib/aws-logs';


export class EksStack extends cdk.Stack {
    counter: number;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', {
      vpcName: 'FisStackVpc/FisVpc'
    });

    // The EKS cluster, without worker nodes as we'll add them later
    const eksCluster = new eks.Cluster(this, 'Cluster', {
      vpc: vpc,
      version: eks.KubernetesVersion.V1_26,
      defaultCapacity: 0,
      clusterName: "FisWorkshop-EksCluster"
    });


    const lt = new ec2.CfnLaunchTemplate(this, 'LaunchTemplate', {
     launchTemplateData: {
       instanceType: 't3.medium',
       tagSpecifications: [{resourceType: 'instance',
      tags: [{
        key: 'Name',
        value: 'FisEKSNode',
      }],}]
     }
    });

    const eksNodeGroup = eksCluster.addNodegroupCapacity("ManagedNodeGroup", {
      desiredSize: 1,
      nodegroupName: "FisWorkshopNG",
      tags: {
        "Name": "FISTarget"
      },
      launchTemplateSpec: {
        id: lt.ref,
        version: lt.attrLatestVersionNumber,
      },
    });

    // Add SSM access policy to nodegroup
    eksNodeGroup.role.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonSSMManagedInstanceCore"));

    const appLabel = { app: "hello-kubernetes" };

    const deployment = {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: { name: "hello-kubernetes" },
      spec: {
        replicas: 1,
        selector: { matchLabels: appLabel },
        template: {
          metadata: { labels: appLabel },
          spec: {
            containers: [
              {
                name: "hello-kubernetes",
                image: "paulbouwer/hello-kubernetes:1.5",
                ports: [ { containerPort: 8080 } ]
              }
            ]
          }
        }
      }
    };

    const service = {
      apiVersion: "v1",
      kind: "Service",
      metadata: { name: "hello-kubernetes" },
      spec: {
        type: "LoadBalancer",
        ports: [ { port: 80, targetPort: 8080 } ],
        selector: appLabel
      }
    };

    eksCluster.addManifest('hello-kub', service, deployment);

    const eksUrl = new cdk.CfnOutput(this, 'FisEksUrl', {
      value: 'http://' + eksCluster.getServiceLoadBalancerAddress("hello-kubernetes")
    });

    const kubeCtlRole = new cdk.CfnOutput(this, 'FisEksKubectlRole', {
      value: eksCluster.kubectlRole?.roleArn.toString() ? eksCluster.kubectlRole?.roleArn.toString() : "undefined"
    });

    this.counter = 1;
    this.node.findAll().forEach((construct, index) => {
          if (construct instanceof lambda.Function) {
            new logs.LogGroup(this, `LogGroup${this.counter}`, {
                logGroupName: `/aws/lambda/${construct.functionName}`,
                retention: logs.RetentionDays.THREE_MONTHS,
                removalPolicy: cdk.RemovalPolicy.DESTROY
            });
            this.counter += 1;
          }

    });

  }
}
