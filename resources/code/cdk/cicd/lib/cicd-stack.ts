import * as cdk from '@aws-cdk/core';
import * as codebuild from '@aws-cdk/aws-codebuild';
import * as codecommit from '@aws-cdk/aws-codecommit';
import * as codepipeline from '@aws-cdk/aws-codepipeline';
import * as codepipeline_actions from '@aws-cdk/aws-codepipeline-actions';
import * as iam from '@aws-cdk/aws-iam'
import * as ec2 from '@aws-cdk/aws-ec2'

export class CicdStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'FisVpc', { 
      vpcName: 'FisStackVpc/FisVpc'
    });
    
    const fisRepo = new codecommit.Repository(this,'fisRepo',{
      repositoryName: "FIS_Workshop",
      description: "Sample Fault Injection Simulator Workshop Repository",
    });

    const fisBuild = new codebuild.PipelineProject(this,'fisBuild',{
      projectName: "FIS_Workshop",
      buildSpec: codebuild.BuildSpec.fromSourceFilename("buildspec.yaml"),
      environment:{
        buildImage: codebuild.LinuxBuildImage.STANDARD_5_0
      }
    });

    fisBuild.role?.addToPrincipalPolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        resources:["*"],
        actions: ['fis:*']
      })
    )

    const sourceOutput = new codepipeline.Artifact()
    const fisPipeline = new codepipeline.Pipeline(this, "fisPipeline",{
      pipelineName: "FIS_Workshop",
      stages: [
        {
          stageName: "Source",
          actions: [
            new codepipeline_actions.CodeCommitSourceAction({
              actionName: "CodeCommit_Source",
              branch: "master",
              repository: fisRepo,
              output: sourceOutput
            })
          ]
        },
        {
          stageName: "Infrastructure_Provisioning",
          actions:[
            new codepipeline_actions.CloudFormationCreateUpdateStackAction({
              actionName: "Create_Infrastructure",
              stackName: "fisWorkshopDemo",
              adminPermissions: true,
              templatePath: new codepipeline.ArtifactPath(sourceOutput, "cfn_fis_demos.yaml"),
              parameterOverrides: {
                VPCParameterValue: vpc.vpcId,
                SubnetParameterValue: vpc.publicSubnets[0].subnetId
              }
            })
          ]
        },
        {
          stageName: "FIS",
          actions: [
            new codepipeline_actions.CodeBuildAction({
              actionName: "Fault_Injection",
              project: fisBuild,
              input: sourceOutput
            })
          ]
        }
      ]
    })

    fisPipeline.stage('Infrastructure_Provisioning').actions[0].actionProperties.role?.addToPrincipalPolicy(
      new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      resources:["*"],
      actions: ['fis:*']
    }))
  }
}
