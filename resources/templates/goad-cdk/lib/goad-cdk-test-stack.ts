import * as cdk    from 'aws-cdk-lib';
import {Construct} from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam    from 'aws-cdk-lib/aws-iam';

export class GoadCdkTestStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const goadLambda = new lambda.Function(this, 'LoadGenerator', {
      runtime: lambda.Runtime.GO_1_X,
      code: lambda.Code.fromAsset('load-gen',{
        bundling: {
          // lambci/lambda:build-go1.x
          image: lambda.Runtime.GO_1_X.bundlingImage,
          command: [
            'bash', '-xc', [
              // looks like the ca certs are a bit too old by default
              'yum install -y ca-certificates',
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
      memorySize: 1024

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
