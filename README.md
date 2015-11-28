# .NET Configuration Section Encryption Example

It is possible to use the [RSAProtectedConfigurationProvider Class](https://msdn.microsoft.com/en-us/library/system.configuration.rsaprotectedconfigurationprovider) to encrypt various sections of the web.config for .NET web applications. This is useful if you want to hide the appSettings keys or connectionString section in your configuration file at rest on the disk.

My examples are tested with a .NET 4.5 application on IIS 7.5+. This documentation will explain how to use the [ASP.NET IIS Registration Tool (Aspnet_regiis.exe)](https://msdn.microsoft.com/en-us/library/k6h9cz8h.aspx) to encrypt your configuration section. 

Microsoft provides outdated documentation of this process in [this article](https://msdn.microsoft.com/en-us/library/ms998283.aspx) (which is confusing and can be simplified). The purpose of this tutorial is to explain the bare minimum to get this working in a production environment.

## Objectives
In this tutorial you will learn:

1. How to create/remove/import/export a Key Container
2. Remove/Grant a user permission to a Key Container
3. Web.config sections needed to support encrypted sections
4. How to encrypt and decrypt configuration sections

So what's the point of all this complexity? If your configuration contains sensitive data, you can add a Key Container to your build server and your application servers. This allows you to encrypt certain config sections during the build process and deploy them already encrypted to the web server. That web server will contain the same Key Container and can read the encrypted config file without any of those sensitive configuration keys visible on the application server in plain text.

## Managing Key Containers

The RSAProtectedConfigurationProvider supports containers for key storage. Machine-level Key Containers are available to all users, but a user-level Key Container is available to that user only. In this example, I am working with Machine-level Key Containers.

### Create a Key Container on Server
You need to create a Key Container. Take note of [keyContainerName] below - we'll need to remember what we used when we get to our web.config.

_aspnet_regiis.exe -pc [keyContainerName] -size [keysize] -exp_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pc MyContainer -size 4096 -exp
```
The command above created a Key Container called "MyContainer" on the local server with a size of 4096 bytes. The key is marked as exportable (via the -exp parameter). 

If you have multiple applications on your server, it may be a good idea to use a different Key Container for each application. Depending on how secure you want to be, it is recommended to use one container per app, and to use the same container for the same app on other servers. 

### Export Key Container to File
This is useful if you want to export the Key Container and import it on another machine. You will not be able ti import a working key if you created it without the -pri flag, since the private key will not be exported.

_aspnet_regiis.exe -px [keyContainerName] [filename] -pri_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -px MyContainer C:\MyContainer.xml -pri
```
We just exported the Key Container to a file called C:\MyContainer.xml. Keep this file secure, as it can be imported and used to decrypt config files that were encrypted elsewhere using the same key.

### Import Key Container From File
This will import a Key Container from an exported XML file.

_aspnet_regiis.exe -pi [contanerName] [file]_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pi MyContainer C:\MyContainer.xml 
```

### Grant/Remove User or Group Permissions of Key Container
You must give one or more user accounts permission to decrypt the config sections and for the application to work properly. This should be the Windows/domain account that is running the script _and_ the user the application pool is running as. It can also be a group.

**Grant Permission to a user/group:**

_aspnet_regiis.exe -pa [keyContainerName] [username_or_group]_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pa MyContainer "DOMAIN\svc_MyApp"
```

**Remove Permission of a user/group:**

_aspnet_regiis.exe -pr [keyContainerName] [username_or_group]_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pr MyContainer "DOMAIN\svc_MyApp"
```
### Remove a Key Container from Server
This will delete a Key Container from a server. You will no longer be able to encrypt or decrypt with this key unless you re-import it.

_aspnet_regiis.exe -pc [keyContainerName] -size [keysize] -exp_
```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pc MyContainer -size 4096 -exp
```

## Define EncryptionProvider in Web.Config 
You must add the following to your application's web.config
```xml
  <configProtectedData>
    <providers>
      <add name="RSAEncryptionProvider"
           type="System.Configuration.RsaProtectedConfigurationProvider,
           System.Configuration, Version=4.0.0.0,
           Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a,
           processorArchitecture=MSIL"
           keyContainerName="MyContainer"
           useMachineContainer="true" />
    </providers>
  </configProtectedData>
```
Note two very important attributes:
* **name** specifies the EncryptionProvider name. It can be anything. Throughout this documentation, I use "RSAEncryptionProvider" This name is passed to the decryption command (see below)
* **keyContainerName** is the name of the Key Container. It is passed to a few commands that manage Key Containers on the server. Throughout this documentation, I am using "MyContainer".

Here is a complete [example web.config](https://github.com/jcefoli/.NETConfigSectionEncryption/blob/master/scripts/ExampleApp/web.config) used in my interactive demo below.

## Encrypting Configuration Section
Run the following command to encrypt a specific section of your config file. In this example, we are encrypting the appSettings section:

_aspnet_regiis.exe -pef [configsection] [web-config-directory] -prov [ProviderName]_

```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pef appSettings C:\MyApp -prov RSAEncryptionProvider
```
Note the parameters used above:

* **-pef** _appSettings_ is the configuration section in the web.config to encrypt
* **C:\MyApp** is the path of the web.config file. No trailing slash
* **-prov** pass the Provider Name. Remember we defined this in our web.config?

## Decrypting Configuration Section
Run the following command to decrypt a specific section of your config file. In this example, we are decrypting the appSettings section:

_aspnet_regiis.exe -pdf [configsection] [web-config-directory]_

```
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pef appSettings C:\MyApp -prov RSAEncryptionProvider
```
Note the parameters used above:
* **-pdf** _appSettings_ is the configuration section in the web.config to decrypt
* **C:\MyApp** is the path of the web.config file. No trailing slash

## Live Demo
I provided a numbered order of batch scripts and a sample web.config that will walk you through this entire exercise so you can try it on your own. Follow the steps below to see this in action!

Note, since we're using the machine container, you will still be able to encrypt/decrypt the file on the local computer, even if you remove the key. It will not work on another computer until you import that same Key Container.

1. Create a Key Container called "MyContainer"  by running ``/scripts/01_Create_KeyContainer.bat``
2. Grant your local user permission to the Key Container by running ``/scripts/02_GrantLocalUserPermission.bat``
  * On your local computer, if you are running this as Administrator, this may not be necessary but it is good practice. You can add any local or domain user/group.
3. Open your web.config (``scripts\ExampleApp\web.config``) and note how it's not encrypted
4. Encrypt the webconfig by running ``/scripts/03_EncryptConfig.bat`
5. Reload the web.config in your text editor (``scripts\ExampleApp\web.config``) The appSettings section should not be readable. 
  * Your .NET app would still function normally, as long as the user it is running as has permission to the Key Container.
  * Encrypting will recycle the application pool
6. Decrypt your config again by running ``/scripts/04_DecryptConfig.bat``
7. Practice moving to another computer:
 * Encrypt the config again: ``/scripts/03_EncryptConfig.bat``
 * Export the Key Container ``scripts/05_Export_KeyContainer.bat``
    * It should create a file here: ``scripts/ExportedContainers/MyContainer.xml`` 
 * Copy the entire ``/scripts`` directory to another computer. All of my example scripts will run from any directory and reference themselves.
 * Try to decrypt the web.config file: ``/scripts/04_DecryptConfig.bat``
    * Wrong! It should fail since we didn't import the key yet.
 * Import the Key Container: ``scripts/08_Import_KeyContainer.bat``
 * Grant your local user permission to the Key Container: ``/scripts/02_GrantLocalUserPermission.bat``
 * Now try to decrypt: ``/scripts/04_DecryptConfig.bat``
8. To clean up the system:
  * Delete the Key Container: ``/scripts/07_Delete_KeyContainer.bat``

Congratulations! You encrypted the key on one server, imported it to another and decrypted the config there! 

You can download a utility called [KeyPal](http://www.jensign.com/KeyPal/), which is a console app that displays KeyConainers installed locally. Launch the app, type in "LM" and press enter. You should see your newly created Key Container there. Many others exist by default, and you should not touch them.

## Things to Consider/Gotchas
1. If your XML config is invalid, the process may fail and corrupt your configuration file. Always have a backup or way to revert to an unencrypted state.
2. Any XML comments will be stripped from your config section
3. You can check error handling by looking at  ``/scripts/handleerror.bat``

### Encrypting Included Configuration Sections
If you split out config sections to other files, it's still possible to encrypt those settings, but you need to know a few things first:

Take this example web.config file. Let's see what happens when we encrypt the appSettings and connStrings sections:
```xml
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <appSettings file="C:\MyApp\Config\appSettings.config" />
  <connStrings configSource="C:\MyApp\Config\ConnectionStrings.config" />
  <configProtectedData>
   <providers>
    <add name="RSAEncryptionProvider" type="System.Configuration.RsaProtectedConfigurationProvider, System.Configuration, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL" keyContainerName="MyContainer" useMachineContainer="true" />
   </providers>
  </configProtectedData>
</configuration>
```

**To encrypt the appSettings section:**

```aspnet_regiis.exe -pef appSettings C:\MyApp -prov RSAEncryptionProvider```

Note that because we included the config with _file=_, the contents of ``C:\MyApp\Config\appSettings.config`` will be moved to the web.config and the file _will_ be deleted. When you decrypt this, the appSettings included file will not be recreated and all appSettings Key/value pairs will remain in the web.config.

**To encrypt the connStrings section:**

```aspnet_regiis.exe -pef connStrings C:\MyApp -prov RSAEncryptionProvider```

Note that because we included the config with _configSource=_, the contents of the connStrings section will **NOT** be moved to the web.config and ``C:\MyApp\Config\ConnectionStrings.config`` will _not_ be deleted. The file itself will be encrypted.

For more info on the difference between _file_ and _configSource_, check out this [StackOverflow](http://stackoverflow.com/a/6940086) article.

## Assumptions/Requirements
* All commands are run with Administrator privileges
* Framework: .NET 4.5+ Installed
* We are running a 64 bit .NET app with the following binary path. Different .NET versions may have a different path:
```batch
%windir%\Microsoft.NET\Framework64\v4.0.30319 
```

##Thank You
Thanks for taking the time to look through this tutorial and I hope it was useful. I'd like to give special thanks to [Alexey](https://github.com/alexeymozgovoy), who took time to understand this and share it with me. Send a pull request if you want to contribute to this documentation. Feel free to reach out:

 * [Github](https://github.com/jcefoli)
 * [Twitter](https://twitter.com/jcefoli)