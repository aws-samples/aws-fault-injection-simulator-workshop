import * as cdk from '@aws-cdk/core';
import * as lambda from '@aws-cdk/aws-lambda';
import * as iam from '@aws-cdk/aws-iam';
import * as logs from '@aws-cdk/aws-logs';

export class GoadCdkTestStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const goadLambda = new lambda.Function(this, 'LoadGenerator', {
      runtime: lambda.Runtime.GO_1_X,
      code: lambda.Code.fromAsset('load-gen',{
        bundling: {
          image: lambda.Runtime.GO_1_X.bundlingImage,
          command: [
            'bash', '-xc', [
              'pwd',
              'ls /',
              // 'export GOPATH=/asset-output',
              'export GOOS=linux',
              // 'export TMPDIR=/asset-output/tmp',
              // 'export GOCACHE=/asset-output/cache',
              // 'mkdir $TMPDIR',
              // 'mkdir $GOCACHE',
              'export GOPRIVATE=*',
              'go test -v',
              'go build -o /asset-output/main',
              // 'rm -rf $TMPDIR $GOCACHE ${GOPATH/pkg}'
            ].join(' && '),
          ],
          user: "root"
        },
      }),
      handler: 'main',
      tracing: lambda.Tracing.ACTIVE,
      environment: {
        USE_PUT_METRICS: 'true',
        USE_LOG_METRICS: 'false'        
      },
      timeout: cdk.Duration.minutes(15),
      memorySize: 1024,
      logRetention: logs.RetentionDays.THREE_MONTHS

    });
    goadLambda.role?.addToPrincipalPolicy(new iam.PolicyStatement({
      resources: ['*'],
      actions: ['cloudwatch:PutMetricData'],
      effect: iam.Effect.ALLOW
    }));

    new cdk.CfnOutput(this,'LoadGenArn',{value:goadLambda.functionArn});
    new cdk.CfnOutput(this,'LoadGenName',{value:goadLambda.functionName});
    new cdk.CfnOutput(this,"Image",{value:lambda.Runtime.GO_1_X.bundlingImage.toJSON()})
  }
}
