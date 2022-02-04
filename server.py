import boto3
import json

ec2 = boto3.resource('ec2', 'us-west-2')


def lambda_handler(event, context):

    filters = [
        {'Name': 'tag:Name', 'Values': ['auto stop']},
        {'Name': 'instance-state-name', 'Values': ['running']}
    ]

    instance_collection = ec2.instances.filter(Filters=filters)

    # Retrieve instance IDs
    instance_id = [instance.id for instance in instance_collection]

    if(event['requestContext']['path'] == '/stop'):
        ec2.instances.filter(
            Filters=[{'Name': 'instance-id', 'Values': instance_id}]).stop()

        return {
            'statusCode': 200,
            'body': json.dumps("stopping "+str(instance_id)+"...")
        }

    elif(event['requestContext']['path'] == '/tags'):
        instance_tags = [instance.tags for instance in instance_collection]

        return {
            'statusCode': 200,
            'body': json.dumps(instance_tags, indent=4, sort_keys=True)
        }
