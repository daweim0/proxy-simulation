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

3. Set the following environment variables

    ```bash
    export ARM_SUBSCRIPTION_ID="<SubscriptionId>"
    export ARM_TENANT_ID="<Tenant>"
    export ARM_CLIENT_ID="<AppId>"
    export ARM_CLIENT_SECRET="<Password>"
    export TF_VAR_prefix="<prefix to be used for all resources>"
    ```

4. Execute the following commands to deploy the resources declared in the Terraform files:

    ```bash
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

    Note: terraform apply will take approximately 20 minutes to spawn all resources

## Testing different permutations of proxy

Note down the private IP addresses of the 3 proxy VMs

### Testing with no-auth proxy

1. Access console of the <prefix>-clustervm VM by using `Serial Console` on the resource blade of the VM with the following credentials

    ```bash
    username: azureuser
    password: <prefix>Password1234%
    ```

2. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

3. Run the following command to onboard this cluster to Arc:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://<proxynoauth-ip-address>:3128 --proxy-http http://<proxynoauth-ip-address>:3128 --proxy-skip-range 10.96.0.0/16
    ```

4. Follow these [instructions](#extensions-and-proxy) for making your extensions proxy ready.

### Testing with basic auth proxy

1. Access console of the <prefix>-clustervm VM by using `Serial Console` on the resource blade of the VM with the following credentials

    ```bash
    username: azureuser
    password: <prefix>Password1234%
    ```

2. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

3. Run the following command to onboard this cluster to Arc:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://azureuser:<prefix>Password1234%@<proxybasic-ip-address>:3128 --proxy-http http://azureuser:<prefix>Password1234%@<proxybasic-ip-address>:3128 --proxy-skip-range 10.96.0.0/16
    ```

4. Follow these [instructions](#extensions-and-proxy) for making your extensions proxy ready.

### Testing with proxy + cert

1. Access console of the <prefix>-proxycertvm VM by using `Serial Console` on the resource blade of the VM with the following credentials

    ```bash
    username: azureuser
    password: <prefix>Password1234%
    ```

2. Run `cat myCert.crt`. Copy the contents of this file.
3. Access console of the <prefix>-clustervm VM by using `Serial Console` on the resource blade of the VM with the following credentials:

    ```bash
    username: azureuser
    password: <prefix>Password1234%
    ```

4. Save the contents of the above mentioned file as `myCert.crt` in the home directory.
5. If the cluster is already Arc connected, delete the connectedCluster resource and agents by running the following command:
  
    ```bash
    az connectedk8s delete -n <cluster-name> -g <resource-group>
    ```

6. Run the following command to onboard this cluster to Arc:

    ```bash
    az connectedk8s connect -n <cluster-name> -g <resource-group> --proxy-https http://<proxycert-ip-address>:3128 --proxy-http http://<proxycert-ip-address>:3128 --proxy-skip-range 10.96.0.0/16 --proxy-cert ./myCert.crt
    ```

7. Follow these [instructions](#extensions-and-proxy) for making your extensions proxy ready.

### Extensions and proxy

Currently proxy parameters are not propagated from connectedCluster resource to the extensions deployed on them (this is in our backlog). In the interim, please take in the proxy parameters as protected configuration settings on the extension and leverage the same to hydrate proxy related values in your Helm chart. Protected configuration settings is recommended over configuration settings as values for --proxy-https or --proxy-http could contain username and password when basic auth is set up for the proxy server.
