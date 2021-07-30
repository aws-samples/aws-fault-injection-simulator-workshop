import * as cdk from '@aws-cdk/core';
import ec2 = require("@aws-cdk/aws-ec2");
import eks = require('@aws-cdk/aws-eks');

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

    eksCluster.addNodegroupCapacity("ManagedNodeGroup", {
      desiredSize: 1,
      nodegroupName: "FisWorkshopNG",
      tags: {
        "Name": "FISTarget"
      }
    })

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
  }
}
