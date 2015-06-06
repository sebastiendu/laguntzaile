#include <iostream>
#include <fstream>
#include <cstdio>
#include <QtCore>
#include <QCoreApplication>
#include <QSettings>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QProcess>
#include <sysexits.h>
#define HAVE_STDINT_H
#include <mimetic/mimetic.h>
#include <mimetic/utils.h>
#include <iconv.h>
#include <string>
#include <iterator>
#include <errno.h>
#include <stdio.h>
#include <vector>

using namespace std;
using namespace mimetic;

bool preparer(MimeEntity* mimeEntity) {
    // Convertit toutes les parties text/plain et text/html en 8bit UTF-8.
    // Retourne si "_URL_" a bien été placé dans au moins l'une de ces parties.
    bool marqueurTrouve = false;
    ContentType& contentType = mimeEntity->header().contentType();
    if (
            contentType.type() == "text" and (
                contentType.subtype() == "plain" or
                contentType.subtype() == "html")
            )
    {
        Body& body = mimeEntity->body();
        if (mimeEntity->header().hasField(ContentTransferEncoding::label)) {
            istring mechanism = mimeEntity->header().contentTransferEncoding().mechanism();
            if (mechanism == ContentTransferEncoding::base64 or
                mechanism == ContentTransferEncoding::quoted_printable) {
                stringstream nouveauBody;
                ostreambuf_iterator<char> nouveauBodyIterator (nouveauBody);
                if (mechanism == ContentTransferEncoding::base64) {
                    Base64::Decoder decodeur;
                    decode(body.begin(), body.end(), decodeur, nouveauBodyIterator);
                } else {
                    QP::Decoder decodeur;
                    decode(body.begin(), body.end(), decodeur, nouveauBodyIterator);
                }
                body.set(nouveauBody.str());
                mimeEntity->body().set(body);
                mimeEntity->header().contentTransferEncoding().mechanism(ContentTransferEncoding::eightbit);
            }
        }
        const string charset = contentType.param("charset");
        if (!charset.empty() && charset != "utf-8" && charset != "UTF-8" && charset != "us-ascii") {
            size_t taille_de_depart = body.length();
            size_t inbytesleft = taille_de_depart;
            char * input_sequence = (char*) body.c_str();
            size_t outbytesleft = 2 * taille_de_depart;
            char * texte_en_sortie = (char*) malloc(outbytesleft);
            char * output_sequence = texte_en_sortie;
            iconv_t conversion_descriptor = iconv_open("UTF-8", charset.c_str());
            if (iconv(conversion_descriptor, &input_sequence, &inbytesleft, &output_sequence, &outbytesleft) == (size_t) -1) {
                perror("iconv");
            } else {
                body.set(std::string(texte_en_sortie));
                body.resize(2 * taille_de_depart - outbytesleft);
                if (contentType.subtype() == "html") {
                    string intrus = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=" + charset + "\">";
                    string remplacant = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">";
                    size_t index = body.find(intrus);
                    while (index != string::npos) {
                        body.replace(index, intrus.length(), remplacant);
                        index = body.find(intrus);
                    }
                }
                mimeEntity->body().set(body);
                contentType.param("charset", "utf-8");
            }
            iconv_close(conversion_descriptor);
        }
        marqueurTrouve = marqueurTrouve || (mimeEntity->body().find("_URL_") != string::npos);
    } else {
        MimeEntityList::iterator sous_partie_iterator = mimeEntity->body().parts().begin(),
                        fin = mimeEntity->body().parts().end();
        for(;sous_partie_iterator!=fin;++sous_partie_iterator)
            marqueurTrouve = marqueurTrouve || preparer(*sous_partie_iterator);
    }
    return marqueurTrouve;
}

void substituer(MimeEntity * mimeEntity, const string url, const string affectations, const string affectations_html) {
    // Substitue _URL_ et _SUBSTITUTIONS_ dans toutes les parties text/plain et text/html
    ContentType contentType = mimeEntity->header().contentType();
    if (
            contentType.type() == "text" and (
                contentType.subtype() == "plain" or
                contentType.subtype() == "html")
            )
    {
        Body& body = mimeEntity->body();
        string::size_type position;
        while((position = body.find("_URL_")) != string::npos) {
            body.replace(position, sizeof("_URL_") - 1, url);
        }
        while((position = body.find("_AFFECTATIONS_")) != string::npos) {
            body.replace(position, sizeof("_AFFECTATIONS_") - 1, (contentType.subtype() == "html" ? affectations_html : affectations));
        }
    } else {
        MimeEntityList::iterator sous_partie_iterator = mimeEntity->body().parts().begin(),
                        fin = mimeEntity->body().parts().end();
        for(;sous_partie_iterator!=fin;++sous_partie_iterator) {
            substituer(*sous_partie_iterator, url, affectations, affectations_html);
        }
    }
}

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    // Un message de courriel est arrivé à l'adresse prefixe+id_lot_et_cle_du_lot_destinataire@domaine.
    // exemple : lurrama+1_315035469@ldd.fr

    // sur le serveur MX du domaine, dans /etc/alias, l'administrateur aura placé cette ligne :
    // prefixe: |/usr/sbin/relai_de_courriel

    // Les rêglages sont à faire dans un fichier de configuration sous /etc ou ~/.config

    QSettings settings("Les Développements Durables", "Laguntzaile");

    // Vérifications préalables

    QString programme = settings.value("sendmail", "/usr/sbin/sendmail").toString();

    if (!QFile::exists(programme)) {
        qCritical()
                << "Introuvable programme d'envoi du courrier " << programme;
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    vector<const char*> env_requis;
    env_requis.push_back("EXTENSION");
    env_requis.push_back("SENDER");
    env_requis.push_back("USER");
    env_requis.push_back("DOMAIN");

    for (vector<const char*>::const_iterator i = env_requis.begin(); i != env_requis.end(); i++) {
        if (getenv(*i) == NULL) {
            qCritical()
                << "Erreur de lecture de la variable d'environnement" << *i
                << "- normalement le MTA renseigne cette variable.";
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_USAGE;
        }
    }

    // De EXTENSION, tirer l'id du lot de sa clé
    QString extension(getenv("EXTENSION"));

    bool aller = extension.contains(QRegExp("^\\d+_\\d+$"));
    bool retour = extension.contains(QRegExp("^\\d+_\\d+_\\d+$"));
    if (!aller && !retour) {
        qCritical()
                << "Cette adresse est invalide.";
        cout << "5.1.3 Bad destination mailbox address syntax" << endl;
        return EX_NOUSER;
    }

    // Le lot des destinataires est défini dans la base de données
    QSqlDatabase db = QSqlDatabase::addDatabase("QPSQL");

    // Connexion à la base de données
    // FIXME : permettre un accès sans mot de passe
    db.setHostName      (settings.value("database/hostName",        "localhost"     ).toString());
    db.setPort          (settings.value("database/port",            5432            ).toInt()   );
    db.setDatabaseName  (settings.value("database/databaseName",    "laguntzaile"   ).toString());
    db.setUserName      (settings.value("database/userName",        qgetenv("USER") ).toString());
    db.setPassword      (settings.value("database/password",        qgetenv("USER") ).toString());

    if(!db.open()) {
        qCritical()
                << "Erreur d'ouverture de la connexion à la base de données :"
                << db.lastError()
                << "Veuillez vérifier le fichier de configuration"
                << settings.fileName();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    // Un retour en erreur ; débarrassons nous de ce cas spécial en premier
    if (retour) {
        // lire id_lot, id_personne et cle
        QStringList identifiant = extension.split('_');
        int id_lot = identifiant.at(0).toInt();
        int id_personne = identifiant.at(1).toInt();
        int cle = identifiant.at(2).toInt();
        // vérification standard : lot_personne avec la bonne cle, traité et reussi et sans erreur
        QSqlQuery query_lot_personne;
        if(!query_lot_personne.prepare(
                    "select *"
                    " from lot_personne"
                    " where"
                    "  id_lot = :id_lot"
                    "  and id_personne = :id_personne"
                    "  and cle = :cle"
                    "  and traite"
                    "  and reussi"
                    "  and erreur is null")) {
            qCritical()
                    << "Erreur de préparation de la requête d'identification de l'envoi :"
                    << query_lot_personne.lastError();
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_CONFIG;
        }
        query_lot_personne.bindValue(":id_lot", id_lot);
        query_lot_personne.bindValue(":id_personne", id_personne);
        query_lot_personne.bindValue(":cle", cle);
        if(!query_lot_personne.exec()) {
            qCritical()
                    << "Erreur d'execution de la requête d'identification de l'envoi :"
                    << query_lot_personne.lastError();
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_CONFIG;
        }
        if (query_lot_personne.size() != 1) {
            qCritical()
                    << "Cette adresse retour est invalide."
                    << "query_lot_personne.size() = " << query_lot_personne.size()
                    << "id_lot" << id_lot
                    << "id_personne" << id_personne
                    << "cle" << cle
                    << query_lot_personne.executedQuery()
                    << query_lot_personne.boundValues()
                    << ".first()" << query_lot_personne.first();
            cout << "5.1.1 Bad destination mailbox address" << endl;
            return EX_NOUSER;
        }
        // marqué cet envoi comme pas réussi et renseigner l'erreur
        QSqlQuery setLotPersonneEnErreur;
        if (!setLotPersonneEnErreur.prepare(
                    "update lot_personne"
                    " set reussi = false,"
                    " erreur = :erreur"
                    " where id_lot = :id_lot"
                    " and id_personne = :id_personne")) {
            qCritical()
                    << "Erreur de préparation de la requête d'enregistrement de l'erreur d'envoi :"
                    << setLotPersonneEnErreur.lastError();
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_CONFIG;
        }
        QFile in;
        in.open(stdin, QIODevice::ReadOnly);
        setLotPersonneEnErreur.bindValue(":id_lot", id_lot);
        setLotPersonneEnErreur.bindValue(":id_personne", id_personne);
        setLotPersonneEnErreur.bindValue(":erreur", QString(in.readAll()));
        if(!setLotPersonneEnErreur.exec()) {
            qCritical()
                    << "Erreur d'execution de la requête d''identification de l'enregistrement de l'erreur d'envoi :"
                    << setLotPersonneEnErreur.lastError();
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_CONFIG;
        }

        cout << "2.1.5 Destination address valid" << endl;
        return EX_OK;
    }

    // Pas un retour mais un envoi vers un lot de destinataires

    QStringList identifiant = extension.split('_');
    int id_lot = identifiant.at(0).toInt();
    int cle = identifiant.at(1).toInt();

    // Lecture du lot
    QSqlQuery query_lot;
    if (!query_lot.prepare("select * from lot where id=? and cle=?")) {
        qCritical()
                << "Erreur de préparation de la requête de lecture du lot de destinataires :"
                << query_lot.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }
    query_lot.addBindValue(id_lot);
    query_lot.addBindValue(cle);
    if (!query_lot.exec()) {
        qCritical()
                << "Erreur d'execution de la requête de lecture du lot de destinataires :"
                << query_lot.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }
    if (!query_lot.first()) {
        qCritical()
                << "Cette adresse ne correspond pas à un lot de destinataires";
        cout << "5.1.1 Bad destination mailbox address" << endl;
        return EX_NOUSER;
    }
    if (query_lot.value("traite").toBool()) {
       qCritical()
               << "Ce lot a déjà été traité une fois. Il n'est pas possible de réutiliser un même lot.";
       cout << "4.2.1 Mailbox disabled, not accepting messages" << endl;
       return EX_UNAVAILABLE;
    }
//    if (query.value("date_de_creation").toDateTime().secsTo(QDateTime::currentDateTime()) > 24*60*60) {
//        qCritical()
//                << "Ce lot est périmé. Un lot ne reste valide que pendant 24 heures."
//                << "Date de création de ce lot : " << query.value("date_de_creation");
//        cout << "4.2.1 Mailbox disabled, not accepting messages" << endl;
//        return EX_UNAVAILABLE;
//    }

    // Lecture de l'évènement
    int id_evenement = query_lot.value("id_evenement").toInt();
    QSqlQuery query_evenement;
    if (!query_evenement.prepare("select fin from evenement where id=?")) {
        qCritical()
                << "Erreur de préparation de la requête de lecture de l'évenement :"
                << query_evenement.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }
    query_evenement.addBindValue(id_evenement);
    if (!query_evenement.exec()) {
        qCritical()
                << "Erreur d'execution de la requête de lecture de l'évènement :"
                << query_evenement.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }
    if (!query_evenement.first()) {
        qCritical()
                << "Ce lot ne correspond à aucun évènement (base de donnée incohérente)";
        cout << "5.1.1 Bad destination mailbox address" << endl;
        return EX_NOUSER;
    }
/*
    if (query_evenement.value("fin").toDateTime() < QDateTime::currentDateTime()) {
       qCritical()
               << "Cet évènement est déjà terminé.";
       cout << "4.2.1 Mailbox disabled, not accepting messages" << endl;
       return EX_UNAVAILABLE;
    }
*/

    // Le message lui-même est à lire sur l'entrée standard

    istreambuf_iterator<char> bit(cin), eit;
    MimeEntity modele(bit, eit);

    // Adaptons le format du message et vérifions si on y trouve bien _URL_

    bool marqueurTrouve = preparer(&modele);

    if (!marqueurTrouve) {
        qCritical()
                << "Marqueur _URL_ introuvable dans le corps du message.";
        cout << "4.2.4 Mailing list expansion problem" << endl;
        return EX_DATAERR;
    }

    // Virer les headers Return-Path, X-Original-To, Delivered-To, X-*, Received ...
    for (Header::iterator i = modele.header().begin(); i != modele.header().end(); i++) {
        if (i->name() == "Received" ||
                i->name().substr(0,2) == "X-" ||
                i->name() == "Return-Path" ||
                i->name() == "Delivered-To" ||
                i->name() == "Message-Id"
                ) {
            modele.header().erase(i);
        }
    }

    // Récupération de la liste des destinataires
    QSqlQuery query_destinataires;
    if (!query_destinataires.prepare(
                "select distinct concat_ws(' ', prenom, nom) as libelle, email, id_personne, disponibilite.id as id_disponibilite, lot_personne.cle"
                " from lot_personne join personne on id_personne = personne.id"
                " join lot on id_lot = lot.id"
                " left join disponibilite using(id_personne, id_evenement)"
                " where id_lot=?"
                " and email like '%@%'"
                )) {
        qCritical()
                << "Erreur de préparation de la requête de lecture des destinataires du lot :"
                << query_destinataires.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }
    query_destinataires.addBindValue(id_lot);
    if (!query_destinataires.exec()) {
        qCritical()
                << "Erreur d'execution de la requête de lecture des destinataires du lot :"
                << query_destinataires.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    // Préparation des autres requètes dont on va avoir besoin
    QSqlQuery query_affectations;
    if (!query_affectations.prepare(
                "select affectation.id, affectation.statut, affectation.commentaire, tour.debut, tour.fin, poste.nom, poste.description"
                " from affectation"
                " join tour on id_tour = tour.id"
                " join poste on id_poste = poste.id"
                " where id_disponibilite = ?"
                )) {
        qCritical()
                << "Erreur de préparation de la requête de lecture des affectations du destinataire :"
                << query_affectations.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    QSqlQuery setLotPersonneTraite;
    if (!setLotPersonneTraite.prepare(
                "update lot_personne"
                " set"
                " traite = true,"
                " reussi = :reussi,"
                " erreur = :erreur"
                " where id_lot=:id_lot and id_personne=:id_personne"
                )) {
        qCritical()
                << "Erreur de préparation de la requête de marquage des envois traités :"
                << setLotPersonneTraite.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    QSqlQuery setLotTraite;
    if (!setLotTraite.prepare(
                "update lot"
                " set"
                " traite = true,"
                " modele = :modele,"
                " expediteur = :expediteur"
                " where id=:id_lot"
                )) {
        qCritical()
                << "Erreur de préparation de la requête de marquage du lot traité :"
                << setLotTraite.lastError();
        cout << "4.3.5 System incorrectly configured" << endl;
        return EX_CONFIG;
    }

    // Génération et envoi des messages personnalisés
    while (query_destinataires.next()) {
        QString libelle = query_destinataires.value("libelle").toString().trimmed();
        QString email = query_destinataires.value("email").toString().trimmed();
        int id_personne = query_destinataires.value("id_personne").toInt();
        int cle = query_destinataires.value("cle").toInt();

        stringstream b;
        b << modele;
        string s = b.str();
        MimeEntity instance(s.begin(), s.end());

        // Personnalisation du from, pour pouvoir identifier les personnes injoignables
        QString fromMailbox = QString("%1+%2_%3_%4").arg(getenv("USER")).arg(id_lot).arg(id_personne).arg(cle);
        QString fromDomaine = getenv("DOMAIN");

        MailboxList& from = instance.header().from();
        for (MailboxList::iterator i = from.begin(); i != from.end(); i++) {
            i->mailbox(fromMailbox.toStdString());
            i->domain(fromDomaine.toStdString());
        }

        // Génération du to
        Mailbox mailbox;
        mailbox.label(libelle.toStdString());
        mailbox.mailbox(email.split('@').at(0).toStdString());
        mailbox.domain(email.split('@').at(1).toStdString());
        MailboxList to;
        to.push_back(mailbox);
        instance.header().to(to.str());

        // substitution des marqueurs
        string url = settings.value("modele_url", "http://localhost/%1/%2").toString().arg(id_evenement).arg(id_personne).toStdString();
        string affectations = "";
        string affectations_html = "";
        if (!query_destinataires.value("id_disponibilite").isNull()) { // le destinataire est inscrit à l'évènement et a peut-être des affectations
            int id_disponibilite = query_destinataires.value("id_disponibilite").toInt();
            query_affectations.addBindValue(id_disponibilite);
            if (!query_affectations.exec()) {
                qCritical()
                        << "Erreur d'execution de la requête de lecture des affectations du destinataire :"
                        << query_affectations.lastError();
                cout << "4.3.5 System incorrectly configured" << endl;
                return EX_CONFIG;
            }
            if (query_affectations.size() > 0) { // il a des affectations
                affectations_html = settings.value("modele_affectations_html_prefixe", "<table><tr><th>De</th><th>à</th><th>Poste</th></tr>").toString().toStdString();
                while (query_affectations.next()) {
                    QString debut = query_affectations.value("debut").toDateTime().toString(); // TODO : formater les dates et les heures
                    QString fin = query_affectations.value("fin").toDateTime().toString();
                    QString nom = query_affectations.value("nom").toString();
                    affectations += settings.value("modele_affectations_texte", "%1 → %2 : %3\n").toString().arg(debut, fin, nom).toStdString();
                    affectations_html += settings.value("modele_affectations_html", "<tr><td>%1</td><td>%2</td><td>%3</td></tr>").toString().arg(debut, fin, nom).toStdString(); // TODO : htmlentities()
                }
                affectations_html += settings.value("modele_affectations_html_suffixe", "</table>").toString().toStdString();
            }
        }
        substituer(&instance, url, affectations, affectations_html);

        // envoi du message et marquage des destinataires traités
        QProcess sendmail;
        QStringList arguments;
        arguments << "-f" << QString("%1@%2").arg(fromMailbox).arg(fromDomaine);
        arguments << email;
        stringstream ss; ss << instance;
        QString entree = QString::fromStdString(ss.str());
        entree.replace(QString("\n.\n"), QString("\n..\n"));
        sendmail.start(programme, arguments);
        if (sendmail.waitForStarted()) {
            sendmail.write(entree.toUtf8());
            sendmail.closeWriteChannel();
            if (sendmail.waitForFinished() && sendmail.exitStatus() == QProcess::NormalExit && sendmail.exitCode() == EX_OK) {
                setLotPersonneTraite.bindValue(":reussi", true);
                setLotPersonneTraite.bindValue("erreur", QVariant());
            } else {
                setLotPersonneTraite.bindValue(":reussi", false);
                setLotPersonneTraite.bindValue("erreur", strerror(sendmail.exitCode()));
            }
        } else {
            setLotPersonneTraite.bindValue(":reussi", false);
            setLotPersonneTraite.bindValue(":erreur", sendmail.readAllStandardError());
        }
        setLotPersonneTraite.bindValue(":id_lot", id_lot);
        setLotPersonneTraite.bindValue(":id_personne", id_personne);
        if(!setLotPersonneTraite.exec()) {
            qCritical()
                << "Erreur d'execution de la requête de marquage des envois traités :"
                << setLotPersonneTraite.lastError();
            cout << "4.3.5 System incorrectly configured" << endl;
            return EX_CONFIG;
        }
    }
    // Marquage du lot traité
    QString sender(getenv("SENDER"));
    setLotTraite.bindValue(":id_lot", id_lot);

    stringstream b;
    b << modele;
    string modele_lot = b.str();
    setLotTraite.bindValue(":modele", modele_lot.c_str());
    setLotTraite.bindValue(":expediteur", sender);
    if(!setLotTraite.exec()) {
        qCritical()
            << "Erreur d'execution de la requête de marquage des envois traités :"
            << setLotTraite.lastError();
        cout << "2.1.5 Destination address valid mais le lot n'a pas été marqué 'traité'" << endl;
        return EX_OK;
    }

    // TODO : poster à SENDER la liste des adresses, nom, prenom, ville et identifiant des destinataires en erreur, le nombre d'envois faits (réussis et ratés), un rappel des sujet et date du message original

    cout << "2.1.5 Destination address valid" << endl;
    return EX_OK;
}
