import * as cdk from '@aws-cdk/core';
import ec2 = require("@aws-cdk/aws-ec2");
import eks = require('@aws-cdk/aws-eks');
import iam = require('@aws-cdk/aws-iam');
import lambda = require('@aws-cdk/aws-lambda');
import logs = require('@aws-cdk/aws-logs');

class CWLogRetCreator implements cdk.IAspect {
    public visit(node: cdk.IConstruct): void {
        if (node instanceof lambda.Function) {
            let fn = (node as lambda.Function);

            new logs.LogGroup(node.stack, `${node.node.id}LogGroup`, {
                logGroupName: `/aws/lambda/${fn.functionName}`,
                retention: logs.RetentionDays.THREE_MONTHS,
                removalPolicy: cdk.RemovalPolicy.DESTROY
            });
        }
    }
}

export class EksStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });

    // The EKS cluster, without worker nodes as we'll add them later
    const eksCluster = new eks.Cluster(this, 'Cluster', {
      vpc: vpc,
      version: eks.KubernetesVersion.V1_20,
      defaultCapacity: 0,
      clusterName: "FisWorkshop-EksCluster"
    });

    const eksNodeGroup = eksCluster.addNodegroupCapacity("ManagedNodeGroup", {
      desiredSize: 1,
      nodegroupName: "FisWorkshopNG",
      tags: {
        "Name": "FISTarget"
      }
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

    //Walk the tree and set retention on all lambda functions
    cdk.Aspects.of(eksCluster).add(new CWLogRetCreator);

    const eksUrl = new cdk.CfnOutput(this, 'FisEksUrl', {
      value: 'http://' + eksCluster.getServiceLoadBalancerAddress("hello-kubernetes")
    });

    const kubeCtlRole = new cdk.CfnOutput(this, 'FisEksKubectlRole', {
      value: eksCluster.kubectlRole?.roleArn.toString() ? eksCluster.kubectlRole?.roleArn.toString() : "undefined"
    });
  }
}
