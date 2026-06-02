# Progetto: Infrastruttura Terraform - Provisioning VM (libvirt)

Questo repository contiene le configurazioni Terraform per il provisioning automatizzato di macchine virtuali tramite il provider **libvirt**. Il progetto è ottimizzato per creare un ambiente basato su Ubuntu 24.04 (Noble Numbat) gestito tramite KVM/QEMU.

## Struttura del Progetto (Tree)

```text
.
├── cloud_init.tf        # Configurazione User-Data e network-config per le VM
├── locals.tf            # Definizione vms (hostname, IP, risorse)
├── network.tf           # Configurazione del bridge di rete libvirt
├── providers.tf         # Configurazione provider libvirt (dmacvicar/libvirt)
├── terraform.tfstate    # Stato corrente dell'infrastruttura
├── variables.tf         # Input variabili (URI, storage, immagini, chiavi SSH)
├── vm.tf                # Definizione delle risorse libvirt_domain
└── volume.tf            # Gestione volumi (qcow2, cloud-init ISO)
```
## Specifiche Tecniche

### Provider
* **Provider:** `dmacvicar/libvirt` (v0.9.7)
* **Hypervisor:** Gestito tramite URI `qemu:///system`

### Configurazione delle Macchine Virtuali (VM)
Il deployment prevede due nodi configurati tramite `locals.tf`:

* **VM App (`menu-app`):**
    * **IP:** 192.168.1.72
    * **Risorse:** 2 vCPU, 2048 MiB RAM, 10 GB Disk.
* **VM DB (`menu-db`):**
    * **IP:** 192.168.1.73
    * **Risorse:** 2 vCPU, 2048 MiB RAM, 10 GB Disk.

## Networking e Storage
* **Rete:** Le macchine sono collegate a un bridge configurato nel file `network.tf` con gateway `192.168.1.1`.
* **Storage:** Utilizza lo storage pool `default` di libvirt. Il disco di sistema è creato a partire dall'immagine cloud ufficiale di Ubuntu Noble.
* **Cloud-Init:** Ogni VM riceve una configurazione personalizzata (hostname, chiave SSH, rimozione snapd) tramite la creazione dinamica di un file ISO dedicato, gestito in `cloud_init.tf` e `volume.tf`.

## Note Operative

### Variabili
Tutti i parametri, inclusi i server DNS (`1.1.1.1`, `8.8.8.8`) e la chiave SSH pubblica, sono centralizzati in `variables.tf`.

### Deployment
1. Assicurarsi di avere `libvirt` e `terraform` installati correttamente.
2. Eseguire `terraform init` per scaricare il provider.
3. Eseguire `terraform plan` per verificare la configurazione pianificata.
4. Eseguire `terraform apply` per avviare il provisioning delle macchine.

### Stato
Il file `terraform.tfstate` traccia lo stato corrente dell'infrastruttura. È fondamentale non editarlo manualmente.
