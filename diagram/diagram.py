# diagram.py

from diagrams import Cluster, Diagram
from diagrams.aws.general import Client
from diagrams.aws.network import ALB,InternetGateway,NATGateway
from diagrams.aws.compute import EC2AutoScaling
from diagrams.aws.database import RDSPostgresqlInstance
from diagrams.aws.storage import SimpleStorageServiceS3Bucket


with Diagram("TFE Airgapped ASG", show=False, direction="TB"):
    
    client = Client("Client")

    with Cluster("AWS"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("VPC"):
            with Cluster("Availability Zone 1"):
                with Cluster("Public Subnet1"):
                    ngw = NATGateway("NAT Gateway")
                    alb1 = ALB("Load balancer")
                with Cluster("Private Subnet1"):
                    asg1 = EC2AutoScaling("Auto scaling group")
                    postgres1 = RDSPostgresqlInstance("PostgresSQL")

            with Cluster("Availability Zone 2"):
                with Cluster("Public Subnet2"):
                    alb2 = ALB("Load balancer")
            
                with Cluster("Private Subnet2"):
                    postgres2 = RDSPostgresqlInstance("PostgresSQL")
                

        s3bucket = SimpleStorageServiceS3Bucket("S3 bucket")
        s3bucketfiles = SimpleStorageServiceS3Bucket("S3 bucket files")

    client >> alb1
    client >> alb2
    alb1 >> asg1
    alb2 >> asg1
    asg1 >> postgres1
    asg1 >> s3bucket
    asg1 >> s3bucketfiles