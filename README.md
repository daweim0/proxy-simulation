# Arc Proxy Simulation

------

This repo contains Terraform files that can be used to bring up a proxy simulation environment having the following resources:

- Proxy server without authentication (plain squid installation)
- Proxy server with basic authentication
- Proxy server with cert
- Single node K8s cluster with Calico and GlobalNetworkPolicy file applied to simulate proxy like environment at the workload plane of cluster. This VM also has Azure CLI, Helm 3 and latest versions of connectedk8s, k8s-extension and k8sconfiguration CLI extensions installed on the VM.

## Deploy resources

1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started#install-terraform) on your machine.

2. Create a service principal having `Contributor` permissions on your subscription

    ```bash
    az ad sp create-for-rbac
    ```

3. Set the following environment variables:

    ```bash
    export ARM_SUBSCRIPTION_ID="<SubscriptionId>"
    export ARM_TENANT_ID="<Tenant>"
    export ARM_CLIENT_ID="<AppId>"
    export ARM_CLIENT_SECRET="<Password>"
    export TF_VAR_prefix="<prefix to be used for all resources>"
    ```

4. If the public key you want to use for SSH to the VMs is not stored at `~/.ssh/id_rsa.pub`, but at a different path, only then set the following optional environment variable:

    ```bash
    export TF_VAR_publickeypath="<Public key used for SSH into VMs>"
    ```

5. Execute the following commands to deploy the resources declared in the Terraform files:

    ```bash
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

    > [!NOTE]
    > `terraform apply` will take approximately 20 minutes to spawn all resources
    > If you want to use this Terraform template in your e2e test pipeline, add a script task in the last step of the pipeline job that runs `terraform destroy -auto-approve` to clean up all transient resources.

## Testing different permutations of proxy

Note down the private IP addresses of the 3 proxy VMs

### Testing with no-auth proxy

1. SSH into the `<prefix>-clustervm` VM by running the following command:

    ```bash
    ssh azureuser@<public-IP-address-of-clustervm>
    ```

2. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

3. Run the following command to onboard this cluster to Arc:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://<proxynoauth-privateip-address>:3128 --proxy-http http://<proxynoauth-privateip-address>:3128 --proxy-skip-range 10.96.0.0/16,kubernetes.default.svc
    ```

4. Follow these [instructions](#extensions-and-proxy) for adding outbound proxy support to your extension.

### Testing with basic auth proxy

1. SSH into the `<prefix>-clustervm` VM by running the following command:

    ```bash
    ssh azureuser@<public-IP-address-of-clustervm>
    ```

2. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

3. Run the following command to onboard this cluster to Arc after substituting `<prefix>`:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://azureuser:<prefix>welcome@<proxybasic-privateip-address>:3128 --proxy-http http://azureuser:<prefix>welcome@<proxybasic-privateip-address>:3128 --proxy-skip-range 10.96.0.0/16,kubernetes.default.svc
    ```

4. Follow these [instructions](#extensions-and-proxy) for adding outbound proxy support to your extension.

### Testing with proxy + cert

1. SSH into the `<prefix>-proxycertvm` VM by running the following command:

    ```bash
    ssh azureuser@<public-IP-address-of-proxycertvm>
    ```

2. Run `cat myCert.crt`. Copy the contents of this file.
3. Exit from this SSH session by running `exit`
4. SSH into the `<prefix>-clustervm` VM by running the following command:

    ```bash
    ssh azureuser@<public-IP-address-of-clustervm>
    ```

5. Save the contents of the above mentioned file as `myCert.crt` in the home directory.
6. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

7. Run the following command to onboard this cluster to Arc:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://<proxycert-privateip-address>:3128 --proxy-http http://<proxycert-privateip-address>:3128 --proxy-skip-range 10.96.0.0/16,kubernetes.default.svc --proxy-cert ./myCert.crt
    ```

8. Follow these [instructions](#extensions-and-proxy) for adding outbound proxy support to your extension.

## Extensions and proxy

1. Details on what every extension team needs to do to add proxy support is available [here](https://dev.azure.com/msazure/One/_wiki/wikis/One.wiki/138886/Add-outbound-proxy-support?anchor=what-do-extension-authors-need-to-do-to-add-outbound-proxy-support-on-their-extensions%3F)
1. Proxy parameters are propagated from connected cluster to extensions as per [this contract](https://dev.azure.com/msazure/One/_wiki/wikis/One.wiki/142401/Extension-Metadata?anchor=extension-metadata).
