import random
import string
import boto3
import os	

s3 = boto3.resource('s3')
BUCKET = "saved-files-7777"


def handler(event, context):
    #Open a file with rundom name
    file_name = ''.join(random.choice(string.ascii_lowercase) for i in range(24))
    outfile = open("/tmp/" + file_name +'.txt', 'w')

    #Produce the numbers
    for count in range(7):
        #Get a random number.
        num = random.randint(0, 999)

    #Write random intergers in to the file
    outfile.write(str(num))

    #Close the file.
    outfile.close()
    print('Data written to: ' + file_name +'.txt' )
    print(num)

    print('Copy file to S3:')
    s3.Bucket(BUCKET).upload_file("/tmp/" + file_name +'.txt',file_name +'.txt')

    print("Remove local file:")
    os.unlink("/tmp/" + file_name +'.txt')

if __name__ == '__main__':
    handler(None, None)
