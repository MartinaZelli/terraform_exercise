# Infrastruttura lab — VM su libvirt/KVM con OpenTofu

Provisioning dichiarativo di un piccolo lab di macchine virtuali Ubuntu su
libvirt/KVM, tramite **OpenTofu** (compatibile Terraform) e il provider
`dmacvicar/libvirt`. Le VM nascono già configurate via **cloud-init**: utente,
chiave SSH, rete statica, hostname/FQDN e `/etc/hosts`.

Il lab ospita due mondi di directory che convivono: un dominio **Active Directory**
(Samba) e un server **OpenLDAP** standalone.

---

## Requisiti

- **OpenTofu** (o Terraform) ≥ 1.6
- **libvirt** + **QEMU/KVM** attivi sull'host
- Un **bridge di rete** già esistente sull'host (default: `bridge0`) sulla LAN
  `192.168.1.0/24`
- Una **chiave SSH** la cui parte pubblica è in `~/.ssh/id_archvm.pub`
- `virsh` installato (utile per ispezione e per le operazioni manuali descritte sotto)

---

## Struttura dei file

| File | Responsabilità |
|------|----------------|
| `providers.tf` | Provider `dmacvicar/libvirt` (v0.9.7) e connessione all'hypervisor. |
| `variables.tf` | Variabili di input: URI libvirt, pool storage, URL immagine Ubuntu, DNS pubblici, percorso chiave SSH, nome del bridge. |
| `locals.tf` | **Cuore della configurazione**: parametri del lab, default hardware/ruolo, definizione delle VM, e derivazione della rete dal ruolo. |
| `network.tf` | La rete libvirt in modalità *bridge*. |
| `volume.tf` | L'immagine base Ubuntu + i dischi delle VM (con backing store) + le ISO di cloud-init. |
| `vm.tf` | I domini libvirt (le VM vere e proprie), generati con `for_each`. |
| `cloud_init.tf` | I dischi cloud-init: user-data (utente, hostname, FQDN, `/etc/hosts`) e network-config (IP statico, rotte, DNS). |

---

## Le macchine

Le VM sono definite in `locals.tf`. Stato attuale:

| Chiave | Hostname | IP | Ruolo | Membro AD? | RAM | vCPU |
|--------|----------|----|-------|------------|-----|------|
| `dc`   | dc1      | 192.168.1.77 | Domain Controller (Samba AD) | — (è il DC) | 2048 | 2 |
| `lb`   | menu-lb  | 192.168.1.75 | Load balancer (HAProxy) | sì | 1024 | 1 |
| `ldap` | ldap     | 192.168.1.76 | Server OpenLDAP standalone | **no** | 1024 | 1 |
| `app`  | menu-app   | 192.168.1.72 | App (FastAPI) | sì | 1024 | 1 |
| `app2` | menu-app-2 | 192.168.1.74 | App (FastAPI) | sì | 1024 | 1 |
| `db`   | menu-db    | 192.168.1.73 | Database (MySQL) | sì | 1024 | 1 |

> **`app`, `app2`, `db` sono attualmente "parcheggiate"** (commentate in `locals.tf`),
> perché l'applicazione è in fase di riscrittura. Il codice che le definisce resta
> nel file come ricetta: per riattivarle, togli il commento e fai `tofu apply`.

Dimensionamento RAM: i valori sono stati scelti **misurando l'uso reale** (le VM a
riposo usano 300–700 MB), non a stima. Con tutte e sei accese si allocano ~7 GiB,
così stanno comode su un host da 16 GiB. Il DC usa 2 GiB a regime; per *ri-provisionare*
il dominio da zero serve più RAM (4 GiB) — vedi note sotto.

---

## Concetto chiave: la rete è DERIVATA dal ruolo

Questo è il pattern centrale del progetto, vale la pena capirlo.

In `locals.tf` non si scrivono a mano `dominio`, `DNS` e `search domain` di ogni VM.
Si dichiara **cosa** è una macchina con due flag di ruolo:

- `ad_member` — la VM si unisce al dominio Active Directory? (default: `true`)
- `is_domain_controller` — la VM **è** il DC? (default: `false`)

Da questi due flag, un blocco `for` calcola la configurazione di rete:

```hcl
domain      = (DC || membro) ? "ad.lab.home" : "lab.home"
nameservers = DC ? <pubblici> : (membro ? [IP del DC] : <pubblici>)
search      = (DC || membro) ? ["ad.lab.home"] : []
```

Tradotto in regole leggibili:
- **dominio DNS**: il DC e i membri stanno in `ad.lab.home`; i non-membri in `lab.home`.
- **nameservers**: un **membro AD** usa **solo il DC** come DNS (requisito di AD); il
  **DC** usa i DNS pubblici (al primo boot deve installare Samba *prima* di avere un
  proprio DNS); un **non-membro** usa i pubblici.
- **search domain**: `ad.lab.home` per chi è nel dominio, vuoto per gli altri.

**Conseguenza pratica:** aggiungere una macchina al dominio = scrivere `ad_member = true`
(o nulla, è il default). La complessità di rete la calcola il codice. È lo stesso
meccanismo `merge()` usato per `memory`/`vcpu`, applicato in due tappe: prima si
iniettano i default (`vms_merged`), poi si deriva la rete (`vms`).

---

## Uso

```bash
# inizializza (scarica il provider)
tofu init

# allinea la formattazione e valida
tofu fmt
tofu validate

# MOSTRA cosa cambierebbe — guardare SEMPRE prima di applicare
tofu plan

# applica
tofu apply
```

### Aggiungere / togliere una macchina dal dominio AD

In `locals.tf`, nella voce della VM:
- per **escludere** una macchina dal dominio: aggiungi `ad_member = false` (come `ldap`);
- per **includerla**: lascia il default o metti `ad_member = true`.

### Riattivare le VM dell'applicazione

Togli il commento dalle voci `app`, `app2`, `db` in `vms_raw`, poi `tofu apply`.
Nasceranno con la RAM ridimensionata e la configurazione di rete corrente.

---

## Note importanti e insidie note

Questa sezione raccoglie comportamenti del provider e del flusso che è bene conoscere
— sono lezioni imparate sul campo.

### 1. cloud-init agisce solo al PRIMO boot
Modificare `cloud_init.tf` (hostname, DNS, `/etc/hosts`) **non riconfigura** una VM
già esistente: il cloud-init viene letto una sola volta, alla nascita della macchina.
Quindi i fix di rete hanno effetto **sui rebuild futuri**, non sulle VM accese. Per
applicarli a una VM esistente, va ricreata da zero.

### 2. I volumi di storage sono immutabili
Il provider libvirt **non sa aggiornare** un `libvirt_volume` (incluse le ISO
`vm_init_iso`): ogni modifica richiede di distruggere e ricreare. A volte il `plan`
*pianifica* un `update in-place` che poi in `apply` fallisce con
`Storage volumes cannot be updated`. Quando capita, la procedura pulita è:

```bash
# 1) togli gli iso dallo stato (NON tocca codice né disco)
tofu state rm 'libvirt_volume.vm_init_iso["dc"]' 'libvirt_volume.vm_init_iso["lb"]' 'libvirt_volume.vm_init_iso["ldap"]'
# 2) elimina gli iso fisici vecchi
sudo virsh vol-delete dc1-init.iso --pool default
sudo virsh vol-delete menu-lb-init.iso --pool default
sudo virsh vol-delete ldap-init.iso --pool default
# 3) ri-pianifica: ora compaiono come "create"
tofu plan
tofu apply
```

### 3. `-target` e `-replace` sono inaffidabili su questo setup
Con questo provider, `tofu destroy -target=...` ha **ignorato il targeting** e
pianificato la distruzione di *tutte* le risorse. **Non fidarsi** di `-target`/`-replace`
per operazioni distruttive. Per distruggere selettivamente, usare gli strumenti
libvirt diretti e poi riallineare lo stato:

```bash
sudo virsh destroy <nome-vm>                         # spegne (stacca la spina)
sudo virsh undefine <nome-vm> --remove-all-storage   # rimuove VM + dischi
tofu state rm 'libvirt_domain.vm["<chiave>"]' ...    # dimentica le risorse nello stato
```

### 4. `apply` può restituire stati incoerenti (provider giovane)
Cambiando la RAM, il provider può ricreare il dominio internamente e cambiarne l'ID,
producendo `Provider produced inconsistent result after apply (.id ...)`. **Non è un
danno**: la modifica è stata applicata. Si riconcilia lo stato con:

```bash
tofu refresh
tofu plan      # atteso: "No changes"
```

### 5. `running = true` → Terraform tende a tenere le VM accese
Nel codice i domini hanno `running = true`. Se spegni una VM a mano e poi fai `apply`,
Terraform potrebbe **riaccenderla** per far combaciare la realtà con lo stato
desiderato. È il comportamento corretto dell'IaC, ma è bene saperlo.

### 6. Bootstrap dei membri AD
Un membro AD ha il DNS puntato **solo** sul DC. Al primo boot, per fare `apt`, serve
che il DC sia **già acceso e funzionante** (è lui che inoltra le query pubbliche).
Nel flusso incrementale (DC sempre presente) non è un problema; in un `apply` "da zero"
con tutto insieme, accendere/provisionare prima il DC.

---

## Cosa NON sta nel repository (gitignore)

Per igiene, restano fuori dal versionamento: lo stato (`*.tfstate*`), la cartella
`.terraform/`, e qualsiasi file locale con segreti. Le chiavi SSH non sono nel repo:
si referenzia solo il **percorso** della chiave pubblica via variabile.

---

## Dominio del lab

- **Active Directory**: realm `AD.LAB.HOME`, dominio DNS `ad.lab.home`, DC = `dc1` (192.168.1.77)
- **OpenLDAP**: server standalone `ldap` (192.168.1.76), dominio `lab.home` — fuori dal dominio AD
- **Rete**: bridge `bridge0`, LAN `192.168.1.0/24`, gateway `192.168.1.1`

---

*Lab a scopo di studio. Tutto in rete locale, solo software open-source.
La configurazione applicativa (app, database, load balancer) è gestita separatamente
via Ansible.*
