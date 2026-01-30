Aquí tens la planificació succinta per a la Unitat Formativa 1: Persistència en Fitxers del mòdul MP06: Accés a Dades, basada en el currículum oficial del cicle DAM (Decret 260/2013).

Planificació Unitat Formativa 1 (UF1)
Títol: Persistència en fitxers Durada: 32 hores Mòdul: MP06 - Accés a Dades

1. Resultat d'Aprenentatge (RA 1)
Desenvolupa aplicacions que gestionen informació emmagatzemada en fitxers, identificant el camp d'aplicació d'aquests i utilitzant les classes específiques.

2. Criteris d'Avaluació (Indicadors)
Aquests són els criteris oficials que serveixen com a indicadors per avaluar l'assoliment del RA:

a) S'han identificat les classes associades a la gestió de fitxers i directoris.
b) S'han utilitzat classes per a la gestió de fitxers i directoris (creació, esborrat, còpia, moviment, etc.).
c) S'han gestionat els fluxos de dades (streams) d'entrada i sortida.
d) S'han programat operacions de lectura i escriptura en fitxers de text i binaris.
e) S'han utilitzat les classes per a la serialització i deserialització d'objectes (persistència d'objectes).
f) S'han gestionat les excepcions derivades de l'accés a fitxers.
g) S'han desenvolupat aplicacions que treballen amb fitxers XML (lectura/escriptura) utilitzant parsers (DOM/SAX) o llibreries d'enllaç (JAXB/daltres).

3. Continguts
Els continguts clau a impartir per assolir els criteris anteriors:

    1. Gestió del sistema de fitxers:
        * Classes per a rutes, fitxers i directoris (ex. java.io.File, java.nio.file.Path/Files).
        * Operacions de sistema: crear, esborrar, llistar, permisos.

    2. Fluxos de dades (Streams):
        * Tipus de fluxos: bytes (InputStream, OutputStream) vs caràcters (Reader, Writer).
        * Fluxos amb buffer (BufferedReader, etc.).

    3. Fitxers d'accés aleatori:
        * Ús de RandomAccessFile.

    4. Persistència d'objectes:
        * Serialització binària (Serializable, ObjectOutputStream).

    5. Gestió de fitxers XML:
        * Conceptes bàsics XML.
        * Models de processament: DOM (arbre en memòria) i SAX (esdeveniments).
        * Llibreries d'accés i manipulació d'XML.

    6. Gestió d'excepcions:
        * Tractament d'errors específics d'E/S (IOException, FileNotFoundException, etc.).

--- 
Nota: Aquesta UF és la base introductòria abans de passar a bases de dades relacionals (UF2). Es recomana enfocar-ho pràcticament amb Java (llenguatge habitual a DAM).

--- BEGIN PRACTICUM ---

## 1. Gestió del sistema de fitxers

### Taula de referència: Funcions Comunes (System.IO)

| Classe      | Mètode                      | Descripció                                                                 |
|:------------|:----------------------------|:---------------------------------------------------------------------------|
| `Directory` | `Exists(path)`              | Retorna `true` si el directori existeix.                                   |
| `Directory` | `CreateDirectory(path)`     | Crea un directori i tots els subdirectoris necessaris.                     |
| `Directory` | `Delete(path, recursive)`   | Esborra un directori (si `recursive` és true, esborra contingut).          |
| `Directory` | `GetFiles(path)`            | Retorna un array amb els noms dels fitxers del directori.                  |
| `Directory` | `GetDirectories(path)`      | Retorna un array amb els noms dels subdirectoris.                          |
| `File`      | `Exists(path)`              | Retorna `true` si el fitxer existeix.                                      |
| `File`      | `Copy(source, dest)`        | Copia un fitxer existent a una nova ubicació.                              |
| `File`      | `Move(source, dest)`        | Mou un fitxer a una nova ubicació (o canvia el nom).                       |
| `File`      | `Delete(path)`              | Esborra permanentment un fitxer.                                           |
| `File`      | `GetCreationTime(path)`     | Obté la data i hora de creació.                                            |
| `File`      | `GetLastWriteTime(path)`    | Obté la data i hora de l'última modificació.                               |
| `File`      | `GetAttributes(path)`       | Obté els atributs del fitxer (ReadOnly, Hidden...).                        |
| `File`      | `SetAttributes(path, attr)` | Estableix els atributs del fitxer.                                         |
| `Path`      | `Combine(path1, path2)`     | Combina dues rutes de fitxer assegurant el separador correcte.             |
| `Path`      | `GetFileName(path)`         | Obté el nom del fitxer i l'extensió d'una ruta completa.                   |
| `Path`      | `GetExtension(path)`        | Obté l'extensió del fitxer (incloent el punt).                             |

### Taula de referència: Atributs de Fitxer (FileAttributes)

Els mètodes `GetAttributes` i `SetAttributes` utilitzen l'enumeració `FileAttributes`. Els atributs es poden combinar amb l'operador OR (`|`).

| Atribut       | Descripció                                                        |
|:--------------|:------------------------------------------------------------------|
| `ReadOnly`    | El fitxer és de només lectura.                                    |
| `Hidden`      | El fitxer està ocult en el llistat de directori normal.           |
| `System`      | El fitxer és d'ús exclusiu del sistema operatiu.                  |
| `Directory`   | L'element és un directori.                                        |
| `Archive`     | L'estat d'arxiu (utilitzat per aplicacions de backup).            |
| `Normal`      | Sense atributs especials. (S'esborra si es combinen altres).      |
| `Temporary`   | Fitxer temporal.                                                  |

**Exemple d'ús:**
```csharp
// Fer un fitxer ocult i de només lectura
File.SetAttributes(path, FileAttributes.Hidden | FileAttributes.ReadOnly);
```

### Exercici 1: Completar (Files & Directories)
Completa el codi següent per comprovar si existeix un directori i crear-lo si no existeix.

```csharp
using System.IO;

string path = @"X:\PlanetaHostil\Bunker";

if (!Directory.________(path)) // Comprovar supervivència de l'estructura
{
    Directory.________(path); // Construir refugi
    Console.WriteLine("Refugi establert.");
}
else 
{
    Console.WriteLine("El refugi ja va ser conquerit.");
}

string filePath = Path.________(path, "diari_supervivent.log"); // Camuflar rutes
if (File.________(filePath)) // Detectar rastres anteriors
{
    File.________(filePath); // Eliminar proves
}
```

### Exercici 1-B: Gestió de Permisos (UnauthorizedAccessException)
Intenta accedir als protocols de seguretat de la Nau Mare (`C:\Windows\System32\config\SAM`) i gestiona l'accés denegat.

```csharp
try 
{
    // Intentar hackear el sistema
    string content = File.ReadAllText(@"C:\Windows\System32\config\SAM");
}
catch (____________ ex) // Captura la contramedida de seguretat
{
    Console.WriteLine("ACCÉS DENEGAT: Protocols de seguretat actius.");
    Console.WriteLine($"Detalls: {ex.Message}");
}
catch (IOException ex)
{
    Console.WriteLine("Error de comunicació amb el mainframe.");
}
```

### Exercici 2: Programació (Skeleton)
Implementa la funció `LlistarAmbulancies` perquè mostri els vehicles d'emergència (fitxers `*.amb`) que han de ser revisats (mida > 1KB).

```csharp
public void LlistarAmbulanciesPerRevisio(string garatgePath)
{
    try 
    {
        // 1. Obtenir els noms d'ambulàncies (extensió .amb)
        // Pista: Directory.GetFiles
        string[] ambulancies = ________________________________;

        foreach (string vehicle in ambulancies)
        {
            FileInfo info = new FileInfo(vehicle);
            // 2. Només mostrar si pesa més de 1024 bytes
            if (________________) 
            {
                Console.WriteLine($"Revisar: {Path.GetFileName(vehicle)}");
            }
        }
    }
    catch (DirectoryNotFoundException)
    {
        Console.WriteLine("El garatge ha estat destruït.");
    }
}
```

### Exercici 4: Debugging (Troba l'error)
El següent codi intenta esborrar un directori "temporal", però llança una excepció `IOException`. Per què? (Suposa que el directori conté fitxers).

```csharp
public void NetejarZona(string zonaPath)
{
    if (Directory.Exists(zonaPath))
    {
        // ERROR: Això fallarà si hi ha runa (fitxers) dins!
        Directory.Delete(zonaPath); 
        
        // CORRECCIÓ: Com s'hauria de fer si volem forçar l'esborrat?
        // Directory.Delete(zonaPath, ____);
    }
}
```

## 2. Fluxos de dades (Streams)
| Classe | Mètode / Propietat | Descripció |
| :--- | :--- | :--- |
| **FileStream** | `Read(byte[], int, int)` | Llegeix un bloc de bytes del flux i els desa en un array. |
| **FileStream** | `Write(byte[], int, int)` | Escriu un bloc de bytes al fitxer des d'un array. |
| **FileStream** | `Seek(long, SeekOrigin)` | Mou el punter de lectura/escriptura a una posició específica. |
| **FileStream** | `Length` | Propietat que retorna la mida total del fitxer en bytes. |
| **StreamReader** | `ReadLine()` | Llegeix la següent línia de caràcters i la retorna com a `string`. |
| **StreamReader** | `ReadToEnd()` | Llegeix tot el contingut des de la posició actual fins al final. |
| **StreamReader** | `Peek()` | Retorna el següent caràcter sense avançar el punter (útil per bucles). |
| **StreamReader** | `EndOfStream` | Booleà que indica si s'ha arribat al final del flux de dades. |
| **StreamWriter** | `Write(string)` | Escriu text al flux sense afegir un salt de línia. |
| **StreamWriter** | `WriteLine(string)` | Escriu text seguit d'un terminador de línia (més comú). |
| **StreamWriter** | `Flush()` | Força l'escriptura de les dades del buffer al fitxer físic. |
| **Comú** | `Close()` / `Dispose()` | Tanca el flux i allibera el fitxer per a altres processos. |

### Exercici 1: Completar (StreamReader/Writer)
Transmissió de dades alienígenes: Llegeix caràcters del flux d'entrada i inverteix el text abans de guardar-lo.

> **Concepte Clau: La sentència `using`**
> 
> La instrucció `using` garanteix que els objectes que consumeixen recursos externs (com fitxers, fluxos de dades o connexions a BD) s'alliberin i es tanquin automàticament en sortir del bloc de codi, fins i tot si es produeix una excepció. És la forma recomanada de gestionar fitxers per evitar bloquejos i fuites de memòria, ja que equival a un bloc `try-finally` que crida automàticament al mètode `.Dispose()`.

```csharp
using System.IO;

string source = "transmissio_rebuda.dat";
string dest = "descodificat.txt";

using (StreamReader reader = new ________(source))
using (StreamWriter writer = new ________(dest))
{
    string line;
    while ((line = reader.________()) != null) 
    {
        // Invertir cadena (Lògica 'estranya' per evitar autocompletat simple)
        char[] charArray = line.ToCharArray();
        Array.Reverse(charArray);
        writer.________(new string(charArray)); 
    }
}
```

### Exercici 2: Programació (Skeleton)
Clonació de Memòria de Robot: Copia el firmware byte a byte però ometent els bytes que siguin `0x00` (sectors buits).

```csharp
public void ClonarFirmwareOptimitzat(string origen, string desti)
{
    using (FileStream fsIn = new FileStream(origen, FileMode.______))
    using (FileStream fsOut = new FileStream(desti, FileMode.______))
    {
        int byteRead;
        while ((byteRead = fsIn._______()) != -1)
        {
            // Només escriure si NO és un sector buit (0)
            if (byteRead != 0)
            {
                fsOut._______((byte)byteRead);
            }
        }
    }
}
```

### Exercici 3: Debugging (Troba l'error)
Un usuari es queixa que el programa peta dient que "El fitxer està sent utilitzat per un altre procés" just quan intenta moure'l després de crear-lo. On és l'error?

```csharp
public void CrearIMoure(string path)
{
    StreamWriter sw = new StreamWriter(path); // Obre flux
    sw.WriteLine("Dades importants");
    // sw.Close(); // <--- FALTA AIXÒ! O fer servir 'using'
    
    // ERROR: El fitxer continua bloquejat pel StreamWriter obert dalt
    File.Move(path, path + ".bak"); 
}
```

## 3. Fitxers d'accés aleatori
L'**accés seqüencial** implica processar les dades de manera lineal, des de l'inici fins al final, mètode habitual per a fitxers de text on la mida de cada línia pot variar. Per contra, l'**accés aleatori** permet moure el punter de lectura/escriptura directament a qualsevol posició (*offset*) sense recórrer les dades anteriors, sent ideal per a fitxers binaris amb estructures de mida fixa.

| Categoria | Classe | Mètodes / Propietats | Descripció |
| :--- | :--- | :--- | :--- |
| **Text** | `StreamReader` | `ReadLine()`, `ReadToEnd()`, `Peek()` | Lectura seqüencial de caràcters i línies. |
| | `StreamWriter` | `Write()`, `WriteLine()`, `Flush()` | Escriptura de text amb gestió de buffers. |
| **Binari** | `BinaryReader` | `ReadInt32()`, `ReadDouble()`, `ReadString()` | Lectura de tipus primitius en format binari. |
| | `BinaryWriter` | `Write(value)` | Escriptura de dades primitives en format binari. |
| **Aleatori** | `FileStream` | `Seek(long, SeekOrigin)`, `Position` | Control directe del punter de posició en el fitxer. |
| | `SeekOrigin` | `Begin`, `Current`, `End` | Especifica el punt de referència per al desplaçament. |


### Exercici 1: Completar (Seek)
Caixa forta antiga: Per obrir-la, has de llegir exactament el byte en la posició 1337 sense tocar res més.

```csharp
using System.IO;

using (FileStream fs = new FileStream("caixa_forta.dat", FileMode.Open))
{
    // Saltar directament al mecanisme d'obertura (offset 1337)
    fs.________(1337, SeekOrigin.Begin);
    
    // Obtenir la combinació
    int combinacio = fs.ReadByte();
}
```

### Exercici 2: Programació (Skeleton)
Marca d'aigua en imatge RAW: Escriu la teva signatura (enter ID) al final del fitxer d'imatge sense sobreescriure les dades d'imatge.

```csharp
public void SignarImatge(string pathImatge, int idAutor)
{
    // ATENCIÓ: Quin mode cal per NO esborrar el contingut existent?
    using (FileStream fs = new FileStream(pathImatge, FileMode.______))
    {
        // 1. Anar al final absolut del fitxer
        fs.Seek(____, SeekOrigin.____);

        // 2. Gravar la signatura de l'autor
        byte[] dades = BitConverter.GetBytes(idAutor);
        fs.Write(____, ____, ____);
    }
}
```

### Exercici 4: Debugging (Troba l'error)
El becari intenta llegir un fitxer, però obté una `UnauthorizedAccessException` o similar tot i el fitxer existir. Què passa amb el `FileMode` i `FileAccess`?

```csharp
public void LlegirSecret(string path)
{
    // ERROR: Estem obrint amb accés Write (per defecte en alguns constructors) o mode erroni?
    // En realitat: FileStream(path, FileMode.Open) per defecte és ReadWrite.
    // Si l'usuari només té permisos de lectura, això petarà.
    
    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.ReadWrite)) 
    {
        int b = fs.ReadByte();
    }
    
    // CORRECCIÓ: Si només volem llegir, hem de demanar només lectura explícitament:
    // new FileStream(path, FileMode.Open, FileAccess.____);
}
```

## 4. Persistència d'objectes (JSON)

La **serialització** és el procés de convertir l'estat d'un objecte (les seves propietats i dades) en un format que pugui ser fàcilment emmagatzemat o transmès (com JSON, XML o format binari). La **deserialització** és el procés invers, on es reconstrueix l'objecte original a partir de les dades serialitzades.

Aquest mecanisme és fonamental en els següents escenaris:
- **Persistència de dades**: Guardar configuracions, preferències d'usuari o l'estat d'una aplicació en un fitxer de disc per a un ús posterior.
- **Comunicació entre sistemes**: Enviar objectes a través d'una xarxa (per exemple, mitjançant una API Web o serveis de missatgeria).
- **Intercanvi d'informació**: Compartir dades entre aplicacions heterogènies que poden estar escrites en diferents llenguatges de programació gràcies a formats estàndard.


| Mètode / Classe | Descripció |
| :--- | :--- |
| `JsonSerializer.Serialize(obj)` | Converteix un objecte de C# en una cadena de text en format JSON. |
| `JsonSerializer.Deserialize<T>(json)` | Reconstrueix un objecte del tipus `T` a partir d'una cadena JSON. |
| `JsonSerializer.SerializeAsync(stream, obj)` | Serialitza l'objecte i escriu el resultat directament en un flux (ex: `FileStream`). |
| `JsonSerializer.DeserializeAsync<T>(stream)` | Llegeix d'un flux i deserialitza l'objecte de forma asíncrona. |
| `JsonSerializerOptions` | Classe per configurar el comportament (indentació, política de noms, etc.). |
| `[JsonPropertyName("nom")]` | Atribut per mapar una propietat a un nom de clau JSON específic. |
| `[JsonIgnore]` | Atribut per evitar que una propietat s'inclogui en el JSON. |


### Exercici 1: Completar (JsonSerializer)
Configuració de Drons: Guarda i recupera la configuració de vol.

```csharp
using System.Text.Json;

public class Dron { public string Model { get; set; } public int Bateria { get; set; } }

Dron unitat = new Dron { Model = "Reaper-X", Bateria = 100 };

// Serialitzar la unitat per transmissió
string jsonString = JsonSerializer.________(unitat);
File.WriteAllText("estat_dron.json", jsonString);

// Recuperar unitat després de l'aterratge
string readJson = File.ReadAllText("estat_dron.json");
Dron unitatRecuperada = JsonSerializer.________<Dron>(readJson);
```

### Exercici 2: Programació (Skeleton)
Inventari de Minerals Rares: Guarda una llista de minerals trobats a Mart, formatant el JSON perquè sigui llegible per humans (`WriteIndented`).

```csharp
public class Mineral { public string Nom { get; set; } public double Radioactivitat { get; set; } }

public void ArxivarMinerals(List<Mineral> sac, string path)
{
    // 1. Configurar per a que el JSON tingui espais i salts de línia
    var options = new JsonSerializerOptions { WriteIndented = ____ };
    
    // 2. Generar l'informe
    string json = ________________________________;

    // 3. Enviar a l'arxiu
    File.WriteAllText(path, json);
}
```

### Exercici 4: Debugging (Troba l'error)
Per què el fitxer JSON resultant està buit `{}` tot i que l'objecte `Secret` té dades?

```csharp
public class SecretBag
{
    // ERROR: JsonSerializer només serialitza propietats PÚBLIQUES!
    private string Codi { get; set; } = "XYZ-123"; 
    public int Nivell { get; set; } = 5;
}

// CORRECCIÓ: Canviar 'private' per '____'
```

## 5. Gestió de fitxers XML

| Classe / Mètode | Descripció |
| :--- | :--- |
| `XDocument` | Representa el document XML complet (declaració, arrel, comentaris). |
| `XElement` | Representa un element XML. És la classe principal per manipular nodes. |
| `XAttribute` | Representa un atribut d'un element (parella clau-valor). |
| `XDocument.Load()` | Carrega el contingut XML des d'un fitxer o una URL. |
| `XDocument.Parse()` | Crea un objecte XML a partir d'una cadena de text (string). |
| `Element("nom")` | Retorna el primer subelement que coincideix amb el nom. |
| `Elements("nom")` | Retorna una col·lecció de subelements per poder iterar-los. |
| `Attribute("nom")` | Retorna l'atribut especificat d'un element. |
| `Descendants("nom")` | Cerca tots els elements descendents en qualsevol nivell de profunditat. |
| `Add()` | Afegeix nou contingut (elements o atributs) com a fills. |
| `Remove()` | Elimina el node actual del seu pare. |
| `Save()` | Guarda els canvis en un fitxer físic. |
| `Value` | Propietat per obtenir o modificar el text contingut en un element o atribut. |


### Exercici 1: Completar (XDocument / Linq to XML)
Servidor Intergalàctic: Modificar el port de comunicació en el fitxer de configuració de la nau.

```csharp
using System.Xml.Linq;

// Carregar configuració de la nau
XDocument doc = XDocument.________("nau_config.xml");

// Obtenir el node del Modul de Comunicacions
XElement modulComm = doc.Element("Nau").Element("Sistemes").Element("Comunicacions");

// Llegir freqüència actual
string freq = modulComm.Element("Frequencia").________;

// Canviar a canal segur
modulComm.Element("Frequencia").Value = "Encrypted-5G";

// Persistir canvis
doc.________("nau_config_v2.xml");
```

### Exercici 2: Programació (Skeleton)
Llibre d'Encanteris: Crea un XML amb encanteris prohibits de manera programàtica. Estructura: `<Llibre><Encanteri>Foc</Encanteri></Llibre>`.

```csharp
public void EscriureGrimori(string path)
{
    XElement llibre = new XElement("Llibre",
        new XElement("Encanteri", "BolaDeFoc"),
        new XElement("Encanteri", "EscutArca")
    );

    // Crear document i guardar
    XDocument doc = new XDocument(_______);
    doc.Save(path);
}
```

### Exercici 4: Debugging (Troba l'error)
El programa peta amb `NullReferenceException` quan intenta llegir la versió. Què passa si l'element `<Versio>` no existeix a l'XML?

```csharp
public void LlegirVersio(string path)
{
    XDocument doc = XDocument.Load(path);
    
    // ERROR: Si Element("Versio") retorna null (no existeix), accedir a .Value peta.
    string v = doc.Root.Element("Versio").Value;
    
    // CORRECCIÓ: Utilitzar l'operador '?' o fer comprovació de null
    // string v = doc.Root.Element("Versio")?________ ?? "Desconeguda";
}
```

--- END PRACTICUM ---

--- BEGIN FINAL PRACTICUM ---

## Propostes de Projecte Final
Aquests projectes estan dissenyats per combinar l'accés seqüencial i aleatori, utilitzant fitxers d'entrada reals (tipus CSV o text) i requerint manipulació de cadenes i estructures binaries.

### 1. Indexador de Biblioteca Gutenberg (Text a Binari Indexat)
**Objectiu:** Crear un cercador ràpid de paraules en un llibre.
**Entrada:** Un llibre clàssic en format `.txt` (ex: *El Quixot* o *Frankenstein*), descarregat de Project Gutenberg.
**Repte:**
1.  **Exploració (Accés Seqüencial):** Llegir el llibre línia a línia, netejar signes de puntuació i normalitzar a minúscules.
2.  **Construcció d'Índex:** Crear un fitxer binari d'índex (`index.dat`) on la capçalera indiqui l'offset on comencen les paraules de cada lletra (A-Z).
3.  **Cerca (Accés Aleatori):** El programa ha de demanar una lletra i saltar directament (`Seek`) a la secció corresponent del fitxer indexat per mostrar les 10 primeres paraules sense llegir tot l'arxiu.

### 2. Gestor de Base de Dades "Retro" (Importador CSV)
**Objectiu:** Implementar un sistema CRUD sobre un fitxer binari d'amplada fixa.
**Entrada:** Un fitxer `.csv` amb dades obertes (ex: Llista de Museus de Catalunya o Incidències de Transport).
**Repte:**
1.  **Importació (Strings):** Parsejar el CSV (vigilant comes dins de cometes!), truncar o fer *padding* dels strings per ajustar-los a camps de mida fixa (ex: Nom=50 bytes, ID=4 bytes).
2.  **Persistència:** Guardar els registres en un fitxer `.db` (Accés Aleatori).
3.  **Algorisme d'Actualització:** Implementar una funció `ActualitzarRegistre(int id, string nouValor)` que calculi l'offset `(ID * MidaRegistre)` i sobreescrigui només aquell camp sense tocar la resta del fitxer.

### 3. "Log Redactor": Anonimització de Logs de Seguretat
**Objectiu:** Censurar informació sensible directament sobre el fitxer original.
**Entrada:** Un fitxer de logs de servidor Apache/Nginx (simulat o real) de gran mida.
**Repte:**
1.  **Cerca de Patrons:** Detectar IPs (ex: `192.168.X.X`) o emails dins del text.
2.  **Edició "In-Place" (Accés Aleatori sobre Text):** En lloc de crear un fitxer nou, utilitzar `FileStream` per obrir el fitxer en mode lectura/escriptura.
3.  **Algorisme:** Quan es detecta un patró sensible, fer un `Seek` enrere fins a l'inici del patró trobat i sobreescriure'l amb caràcters `X` (ex: `192.168.1.5` -> `XXX.XXX.XXX`). *Nota: Cal gestionar bé la conversió de bytes i la posició del cursor.*

### 4. Esteganografia en Imatges BMP (Bitmap Header Hack)
**Objectiu:** Amagar un missatge secret dins de la capçalera no utilitzada o els píxels d'una imatge.
**Entrada:** Una imatge `.bmp` senzilla (format no comprimit).
**Repte:**
1.  **Analisi Binària:** Llegir la capçalera BMP (primers 54 bytes) per entendre on comencen les dades de píxels (`DataOffset`).
2.  **Injectar Missatge:** Demanar un text a l'usuari i escriure'l byte a byte en els bits menys significatius dels primers píxels, o en bytes reservats de la capçalera (si n'hi ha).
3.  **Recuperació:** Un segon mode del programa ha de fer `Seek` a les posicions conegudes i reconstruir l'string amagat.

### 5. "El Desfragmentador" (Optimització d'Arxius)
**Objectiu:** Compactar un codi font o fitxer de dades eliminant "basura" sense usar memòria intermèdia gran.
**Entrada:** Un fitxer de text amb molts comentaris, espais en blanc sobrants o blocs marcats com `[DELETED]`.
**Repte:**
1.  **Punter de Lectura i Escriptura:** Utilitzar dos punters sobre el mateix fitxer (o lectura seqüencial i escriptura aleatòria en un de nou).
2.  **Algorisme:** Llegir caràcter a caràcter. Si és útil, escriure'l a la posició *compactada*. Si és "basura" (comentari o espai extra), saltar-lo.
3.  **Resultat:** Al final, truncar (`SetLength`) el fitxer a la nova mida real. Requereix lògica per no sobreescriure dades que encara no s'han llegit (si es fa in-place).


--- ENUNCIATS ---

### 1. Indexador de Biblioteca Gutenberg (Text a Binari Indexat)
**Objectiu:** Crear un cercador ràpid de paraules en un llibre.
**Entrada:** Un llibre clàssic en format `.txt` (ex: *El Quixot* o *Frankenstein*), descarregat de Project Gutenberg.
**Repte:**
1.  **Exploració (Accés Seqüencial):** Llegir el llibre línia a línia, netejar signes de puntuació i normalitzar a minúscules.
2.  **Construcció d'Índex:** Crear un fitxer binari d'índex (`index.dat`) on la capçalera indiqui l'offset on comencen les paraules de cada lletra (A-Z).
3.  **Cerca (Accés Aleatori):** El programa ha de demanar una lletra i saltar directament (`Seek`) a la secció corresponent del fitxer indexat per mostrar les 10 primeres paraules sense llegir tot l'arxiu.

```csharp
using System;
using System.Net.Http;
using System.IO;
using System.Threading.Tasks;
using System.Text.Json.Nodes; // Requereix .NET 6+

public class GutenbergProvider 
{
    private static readonly HttpClient client = new HttpClient();

    // Llistar llibres populars (retorna JSON en format String)
    public static async Task<string> ListPopularBooks() 
    {
        // Necessari afegir User-Agent per a algunes APIs
        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (ConsoleApp)");
        return await client.GetStringAsync("https://gutendex.com/books/");
    }

    // Mostrar els llibres obtinguts de la API en format adequat a l'usuari
    public static void DisplayBooks(string jsonResponse) 
    {
        JsonNode root = JsonNode.Parse(jsonResponse);
        JsonArray results = root["results"]!.AsArray();

        foreach (JsonNode book in results) 
        {
            int id = book["id"].GetValue<int>();
            string title = book["title"]?.GetValue<string>() ?? "Sense títol";
            
            string authorName = "Desconegut";
            JsonArray authors = book["authors"]?.AsArray();
            if (authors != null && authors.Count > 0) 
            {
                authorName = authors[0]["name"]?.GetValue<string>() ?? "Desconegut";
            }

            Console.WriteLine($"{id}. {title} ({authorName})");
        }
    }

    // Descarregar un llibre per ID
    public static async Task DownloadBook(int id, string fileName) 
    {
        try 
        {
            string url = $"https://www.gutenberg.org/files/{id}/{id}-0.txt";
            // Nota: Gutenberg sovint redirigeix, HttpClient ho gestiona automàticament per defecte
            byte[] data = await client.GetByteArrayAsync(url);
            await File.WriteAllBytesAsync(fileName, data);
            Console.WriteLine($"[INFO] Llibre {id} descarregat com a {fileName}");
        }
        catch (HttpRequestException e)
        {
            Console.WriteLine($"[ERROR] Error de xarxa: {e.Message}");
        }
    }
}
```

#### 2. Especificació del Repte (Anti-IA)
*Per evitar solucions genèriques de models de llenguatge, s'han d'aplicar les següents restriccions tècniques estrictes:*

1.  **Format Binari Propietari (`.idx`):** No es permet l'ús de bases de dades (SQLite, etc.) ni JSON/XML per a l'índex.
2.  **Estructura del Fitxer d'Índex:**
    *   **Capçalera (Header):** Els primers 208 bytes (26 lletres de l'alfabet A-Z × 8 bytes per un `long`). Cada `long` representa l'offset (posició) on comencen les paraules d'aquella lletra al fitxer. Si no hi ha paraules, l'offset serà `-1`.
    *   **Còs (Data):** Blocs de paraules. Cada entrada de paraula ha de tenir:
        *   Un `byte` que indiqui la longitud de la paraula.
        *   La paraula en format UTF-8.
        *   Un `int` que indiqui la freqüència d'aparició al text original.
3.  **Gestió de Memòria:** Està prohibit carregar tot el llibre o tot l'índex en memòria principal (`List<String>`, `HashMap`). El processament s'ha de fer mitjançant buffers de lectura i l'escriptura de l'índex s'ha de fer saltant amb `seek()` segons la lletra processada.

#### 3. Funcionalitats Requerides
*   **Mode Build (`--build <id>`):** Descarrega el llibre, neteja el text (treu puntuació, passa a minúscules), compta paraules úniques i genera el fitxer `index.dat`.
*   **Mode Search (`--search <lletra>`):** Llegeix el `long` corresponent de la capçalera del fitxer binari, fa un `seek()` a la posició indicada i llegeix seqüencialment només les paraules d'aquella secció.

#### 4. Exemple de Sortida per Consola
```text
> java GutenbergIndexer --build 1342
[1] Descarregant 'Pride and Prejudice'... OK.
[2] Analitzant text i generant índex binari...
    - Paraules processades: 124.592
    - Paraules úniques: 6.530
[3] Escrivint capçalera (A: 208, B: 1405, C: 3560...)
[SUCCESS] Índex generat correctament.

> java GutenbergIndexer --search p
[INFO] Saltant a l'offset 18432 (Secció 'P')...
Resultats (Paraula : Freqüència):
- palace : 12
- paper : 45
- pardon : 8
- particular : 154
- party : 89
...


#### Exemple de Resultat
```
Què vols buscar? A
Aigua
Així
Així
Així
Així
Així
Així
Així
Així
```

### Exercicis de XML i Serialització d'Objectes (Refactoritzat)

Aquests projectes estan dissenyats per practicar la persistència d'estat i la manipulació de dades estructurades en Java/C#, enfocats a cicles formatius de grau superior:

1.  **Gestor d'Inventari de Magatzem:**
    *   **Funcionalitat:** Control d'estoc de productes amb referència, quantitat i preu.
    *   **Serialització:** Desa l'estat de la sessió (usuari actual, darrera cerca realitzada i preferències de visualització) en un fitxer binari `.config`.
    *   **XML:** Utilitza un fitxer XML com a base de dades de productes. L'aplicació ha de permetre afegir nous nodes `<Producte>`, eliminar-ne d'existents i actualitzar els atributs directament al fitxer.

2.  **Planificador de Tasques (To-Do List):**
    *   **Funcionalitat:** Organització de tasques pendents amb prioritats i dates límit.
    *   **Serialització:** Guarda l'objecte `AppStatus` que conté els filtres actius de l'usuari i la posició de la finestra per recuperar-los en reiniciar.
    *   **XML:** Les tasques s'emmagatzemen en un XML. Cal implementar la lògica per inserir tasques, marcar-les com a completades (modificar node) o esborrar-les definitivament del document.

3.  **Registre de Notes Acadèmiques:**
    *   **Funcionalitat:** Gestió d'alumnes i les seves qualificacions per mòduls.
    *   **Serialització:** Persistència de l'estat de l'aplicació, incloent el darrer curs acadèmic seleccionat i el llistat de mòduls carregats en memòria.
    *   **XML:** Desa la llista d'alumnes en XML. Permet afegir nous alumnes, eliminar registres i modificar les notes dins dels elements `<Qualificacio>` mitjançant l'API DOM o LINQ to XML.

4.  **Catàleg de Biblioteca Personal:**
    *   **Funcionalitat:** Registre de llibres amb autor, ISBN i estat de préstec.
    *   **Serialització:** Desa l'objecte `Preferencies` que conté el camí del darrer fitxer XML obert i el mode de visualització (llista o graella).
    *   **XML:** Tota la col·lecció resideix en un XML. L'usuari pot donar d'alta llibres, eliminar títols de la col·lecció i canviar l'estat de "disponible" a "prestat" modificant el fitxer.

5.  **Sistema de Gestió de Cites Mèdiques:**
    *   **Funcionalitat:** Administració de visites per a una clínica petita.
    *   **Serialització:** Guarda l'estat de la interfície, com ara el metge seleccionat per defecte i l'interval horari de visualització preferit.
    *   **XML:** Les cites es guarden en un fitxer XML diari. L'aplicació ha de permetre programar noves cites (afegir node), cancel·lar-les (eliminar node) i reassignar hores (editar node).

DESENVOLUPAMNBET

### Projecte Detallat: Planificador de Tasques (To-Do List)

Aquest projecte consisteix en el desenvolupament d'una aplicació de consola o escriptori per a la gestió de tasques diàries, posant èmfasi en la combinació de dos mecanismes de persistència: serialització binària per a la configuració i XML per a les dades de l'usuari.

#### 1. Requisits del Model de Dades
*   **Classe `Task`:** Ha de contenir els atributs: `ID` (únic), `Descripció` (string), `Prioritat` (Alta, Mitjana, Baixa), `Data Limit` (DateTime) i `Estat` (Pendent/Completada).
*   **Classe `AppStatus`:** Ha de ser marcada com a `[Serializable]` (C#) o implementar `Serializable` (Java). Contindrà:
    *   `UltimFiltre`: Un enumerat o string que indiqui si l'usuari visualitzava "Totes", "Pendents" o "Completades".
    *   `FinestraPosicio`: Un objecte simple amb coordenades `X` i `Y`.

#### 2. Persistència en XML (`tasks.xml`)
L'aplicació ha d'utilitzar una API de processament XML (com DOM, LINQ to XML o `XmlDocument`) per gestionar el fitxer de tasques:
*   **Inserció:** Afegir un nou element `<Tasca>` amb els seus atributs i sub-elements.
*   **Modificació:** Cercar una tasca per `ID` i canviar el valor del node `<Estat>` a "Completada".
*   **Eliminació:** Localitzar un node específic i extreure'l de l'arbre XML.
*   **Consulta:** Filtrar els nodes segons els criteris guardats a la configuració.

#### 3. Persistència Binària (`config.dat`)
En tancar l'aplicació, s'ha de serialitzar l'objecte `AppStatus` en un fitxer binari. En iniciar-se:
*   Si el fitxer existeix, es des-serialitza per restaurar l'estat de la interfície i el filtre de dades.
*   Si no existeix, es crea un objecte amb valors per defecte.

#### 4. Flux de Treball Suggerit
1.  Implementar la serialització de la configuració per assegurar que l'entorn de l'usuari es manté.
2.  Dissenyar l'estructura de l'XML i les funcions de lectura/escriptura (CRUD).
3.  Crear un menú d'usuari que permeti gestionar les tasques i veure com els canvis es reflecteixen immediatament al fitxer `tasks.xml`.

--- ENUNCIAT ANTI0'IA --

### Projecte: TaskMaster Pro (Persistència Híbrida i Seguretat de Configuració)

**Objectiu:** Desenvolupar un gestor de tasques que combini la manipulació manual de nodes XML amb una serialització binària personalitzada per a la configuració, evitant l'ús de serialitzadors automàtics de dades.

#### 1. Restriccions Tècniques Estrictes (Anti-IA)
Per garantir la implementació de lògica pròpia i evitar solucions genèriques:
1.  **Prohibició de `XmlSerializer` / `JsonSerializer`:** Tota interacció amb `tasks.xml` s'ha de fer mitjançant **LINQ to XML (`XDocument`)** o **DOM (`XmlDocument`)**. No es permet mapejar objectes directament a XML.
2.  **Capçalera de Seguretat en Configuració:** El fitxer `config.dat` no pot ser només el resultat de `BinaryFormatter` (o similar). Ha de començar amb una "Magic Number" de 4 bytes (`0x54 0x41 0x53 0x4B`) seguida d'un byte de versió abans de les dades serialitzades de la classe `AppStatus`.
3.  **Format de Data Propietari:** Les dates al XML s'han de guardar en format Unix Timestamp (segons totals) com a atribut del node, no com a string ISO estàndard.

#### 2. Models de Dades
*   **Classe `Task`:** 
    *   `ID` (Guid), `Descripció` (string), `Prioritat` (Enum: Alta, Mitjana, Baixa).
    *   `Deadline` (long - emmagatzemat com a Timestamp).
    *   `Completada` (bool).
*   **Classe `AppStatus`:** (Marcada com `[Serializable]`)
    *   `UltimFiltre`: (Totes, Pendents, Completades).
    *   `Coordenades`: `struct { int X; int Y; }`.

#### 3. Requisits de Persistència
**A. Gestió XML (`tasks.xml`):**
*   **Inserció Atòmica:** Cada vegada que s'afegeix una tasca, s'ha de carregar el fitxer, injectar el node `<Tasca>` amb els atributs `id` i `deadline`, i guardar.
*   **Update In-Place:** Per marcar una tasca com a completada, cal cercar el node per l'atribut `id` i modificar el valor del sub-element `<Estat>`.
*   **Neteja Automàtica:** Implementar una funció que elimini tots els nodes amb una data inferior a l'actual en carregar l'aplicació.

**B. Configuració Binària (`config.dat`):**
*   **Escriptura:** Implementar un `FileStream` que escrigui la capçalera manual (`0x5441534B` + `0x01`) i després utilitzi `BinaryFormatter` (o `BinaryWriter` manual) per a l'objecte `AppStatus`.
*   **Lectura:** Validar els primers 5 bytes abans de procedir a la des-serialització. Si la capçalera és incorrecta, ignorar el fitxer i carregar valors per defecte.

#### 4. Interfície i Flux
1.  **Inici:** L'aplicació llegeix `config.dat`, valida la capçalera i aplica el filtre guardat a la llista de tasques carregada des de `tasks.xml`.
2.  **Operacions:** Menú per (1) Afegir Tasca, (2) Completar Tasca (per ID), (3) Canviar Filtre de Visualització.
3.  **Tancament:** Es guarden les coordenades de "finestra" (simulades en consola) i el filtre actual a `config.dat`.

#### 5. Validació de Sortida
En mode depuració, el programa ha de mostrar per consola:
`[DEBUG] Capçalera config.dat correcta. Carregant filtre: {Filtre}`
`[DEBUG] XML carregat. {N} tasques filtrades i {M} eliminades per caducitat.`

#### Exemple d'execució

> dotnet run TaskMasterPro
[DEBUG] Validant capçalera config.dat... OK (Magic: 0x5441534B, Ver: 0x01)
[DEBUG] Carregant estat: Filtre=Pendents, Posició=(100, 250)
[DEBUG] XML carregat. 3 tasques filtrades i 1 eliminada per caducitat (Timestamp < 1709554800).

--- TASKMASTER PRO ---
Filtre actual: PENDENTS
1. [ID: 7a2b] Preparar examen AD (Alta) - Deadline: 1710244800
2. [ID: f41c] Comprar llet (Baixa) - Deadline: 1709641200

Menú: (1) Afegir, (2) Completar, (3) Filtre, (4) Sortir
> 1
Descripció: Corregir pràctiques
Prioritat (1-Alta, 2-Mitjana, 3-Baixa): 2
Dies fins al deadline: 3
[INFO] Tasca afegida correctament al XML.

Menú: (1) Afegir, (2) Completar, (3) Filtre, (4) Sortir
> 2
Introdueix ID: 7a2b
[INFO] Cercant node <Tasca id="7a2b">...
[INFO] Estat actualitzat a 'Completada' al fitxer tasks.xml.

Menú: (1) Afegir, (2) Completar, (3) Filtre, (4) Sortir
> 3
Nou filtre (1-Totes, 2-Pendents, 3-Completades): 3
[DEBUG] Aplicant filtre 'Completades' sobre l'arbre XML...
1. [ID: 7a2b] Preparar examen AD (Alta) - ESTAT: COMPLETADA

Menú: (1) Afegir, (2) Completar, (3) Filtre, (4) Sortir
> 4
[INFO] Guardant configuració a config.dat...
[DEBUG] Escrivint Magic Number i versió...
[DEBUG] Serialitzant objecte AppStatus (Filtre: Completades, Pos: 100,250)...
[SUCCESS] Aplicació tancada correctament.
