import boto3
import sys
import time

fisClient = boto3.client('fis')


def main(argv):
    experiment_name = argv[0]
    commit_id = argv[1]
    templateID = getExperimentTemplateID(experiment_name)
    if(templateID == None):
        print("Could not find experiment template for [" + experiment_name + "]")
        sys.exit()

    formatted_experiment_name = f"cicd-{experiment_name}-{commit_id}"
    print("Starting new [" + formatted_experiment_name + "] experiment")
    startExperimentResponse = fisClient.start_experiment(
        experimentTemplateId=templateID,
        tags={
            'Name': formatted_experiment_name
        }
    )

    experimentID = startExperimentResponse['experiment']['id']
    experimentStatus = startExperimentResponse['experiment']['state']['status']
    print("Started experiment ID [" + experimentID + "]")
    print("Current status is [" + experimentStatus + "]")

    while(experimentStatus not in ['completed', 'stopped' , 'failed']):
        print("Waiting for experiment to complete. Current Status is [" + experimentStatus + "]")
        time.sleep(30)
        getExperimentResponse = fisClient.get_experiment(
            id = experimentID
        )
        experimentID = getExperimentResponse['experiment']['id']
        experimentStatus = getExperimentResponse['experiment']['state']['status']

    print("Experiment Complete with status [" + experimentStatus + "]")
    print("Result was [" + getExperimentResponse['experiment']['state']['reason'] + "]")

    if(experimentStatus == 'completed'):
        return 0
    else: 
        raise NameError('ExperimentFailed')

def getExperimentTemplateID(experiment):
    print("Getting experiment template for " + experiment)
    templates = fisClient.list_experiment_templates()
    for template in templates['experimentTemplates']:
        if(template['tags']['Name'] == experiment):
            print("Found template with ID [" + template['id'] + "]")
            return template['id']


if __name__ == "__main__":
    main(sys.argv[1:])
