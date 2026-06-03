# Progetto: Infrastruttura OpenTofu - Provisioning VM (libvirt)

Questo repository contiene le configurazioni OpenTofu/Terraform per il provisioning automatizzato di macchine virtuali su Arch Linux tramite il provider **libvirt**. Il progetto è ottimizzato per creare un ambiente multi-nodo basato su Ubuntu 24.04 LTS (Noble Numbat) gestito tramite KVM/QEMU.

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

### Strumento e Provider
* **IaC Engine:** OpenTofu (compatibile con Terraform)
* **Provider:** `dmacvicar/libvirt` (v0.9.7)
* **Hypervisor:** KVM/QEMU locale gestito tramite URI `qemu:///system`

### Configurazione delle Macchine Virtuali (VM)
Il deployment prevede un'architettura a 4 nodes configurata dinamicamente tramite cicli `for_each` basati sui parametri centralizzati in `locals.tf`. Ogni macchina ha un profilo hardware standard di **2 vCPU**, **2048 MiB RAM** e **10 GB di disco**.

* **VM App (`menu-app`):**
    * **IP:** `192.168.1.72` | **MAC:** `02:00:00:01:00:01`
* **VM App 2 (`menu-app-2`):**
    * **IP:** `192.168.1.74` | **MAC:** `02:00:00:01:00:03`
* **VM DB (`menu-db`):**
    * **IP:** `192.168.1.73` | **MAC:** `02:00:00:01:00:02`
* **VM LB (`menu-lb`):**
    * **IP:** `192.168.1.75` | **MAC:** `02:00:00:01:00:04`

## Networking e Storage
* **Rete:** Le macchine sono collegate a un bridge configurato nel file `network.tf` con gateway `192.168.1.1`.
* **Storage:** Utilizza lo storage pool `default` di libvirt. Il disco di sistema è creato a partire dall'immagine cloud ufficiale di Ubuntu Noble.
* **Cloud-Init:** Ogni VM riceve una configurazione personalizzata (hostname, chiave SSH, rimozione snapd) tramite la creazione dinamica di un file ISO dedicato, gestito in `cloud_init.tf` e `volume.tf`.

### Stabilità Hardware Garantita
Le macchine virtuali includono ottimizzazioni strutturali native per l'emulazione:
* **CPU Passthrough:** `host-passthrough` per massimizzare le performance computazionali.
* **RNG Device:** Dispositivo hardware `/dev/urandom` emulato via VirtIO per impedire il blocco del boot a causa della carenza di entropia.
* **Graphics:** Console VNC locale abilitata in ascolto sicuro su `127.0.0.1` con allocazione automatica delle porte.

## Note Operative

### Variabili
Tutti i parametri, inclusi i server DNS (`1.1.1.1`, `8.8.8.8`) e la chiave SSH pubblica, sono centralizzati in `variables.tf`.

### Comandi per il Deployment
1. Inizializzare l'ambiente e scaricare i provider:
   t o f u   i n i t
2. Verificare la conformità sintattica dei file di configurazione:
   t o f u   v a l i d a t e
3. Mostrare il piano delle modifiche pianificate:
   t o f u   p l a n
4. Applicare le modifiche per avviare il provisioning effettivo sul sistema:
   t o f u   a p p l y
5. Per distruggere l'intero ambiente di laboratorio in modo pulito:
   t o f u   d e s t r o y

### Stato
Il file `terraform.tfstate` traccia lo stato corrente dell'infrastruttura. È fondamentale non editarlo manualmente.
