# Infrastructure-as-Code - Realisierung einer Webanwendung in der Public Cloud
## Anmerkungen
Diese Anwendung kann bis zu 1€/h kosten! Wenn sie nicht genutzt wird sollte die Infrastruktur zerstört werden.

## Voraussetzungen
Um die Anwendung zu verwenden benötigen Sie:

* Die installierte [Terraform CLI (1.0.9+)](https://www.terraform.io/downloads)

* Die installierte [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

* Ein [AWS-Konto](https://console.aws.amazon.com/console/home?nc2=h_ct&src=header-signin)
* Ihre AWS-Anmeldedaten. Sie können auf dieser [Seite einen neuen Zugangsschlüssel erstellen](https://console.aws.amazon.com/iam/home?#/security_credentials)


Konfigurieren Sie die AWS CLI von Ihrem Terminal aus. Folgen Sie den Aufforderungen zur Eingabe Ihrer AWS Access Key ID und Ihres Secret Access Key:
```console
$ aws configure
```

## Nutzung der Anwendung
1. Verzeichnis initialisieren:
      ```console
      $ terraform init
      ```

2. Konfiguation anwenden:

      ```console
      $ terraform apply
      ```
      
      ```console
      ...

      Apply complete! Resources: 86 added, 0 changed, 0 destroyed.

      Outputs:

      url = "guestbook.bobcat.s3-website.eu-central-1.amazonaws.com"
      ```
      
      Über die zufällig generierte URL in der Konsolenausgabe kann die Anwendung aufgerufen werden.


3. Wenn die Anwendung nicht mehr benötigt wird kann sie zerstört werden:

      ```console
      $ terraform destroy
      ```


## Troubleshooting

Falls die API mit dem http-Statuscode 500 antwortet, kann die Zerstörung und erneute Anwendung der Konfiguration behilflich sein.