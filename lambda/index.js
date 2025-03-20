exports.handler = async (event) => {
    // Définir le fuseau horaire Paris
    const options = { timeZone: "Europe/Paris", hour12: false, hour: "2-digit", minute: "2-digit" };
    const currentTime = new Intl.DateTimeFormat("fr-FR", options).format(new Date());
    const firstName = "Alexis"; 
    const lastName = "TOULLEC";
    // Modifier avec ton prénom et nom
    const message = `Hello World ! Ici ${firstName} ${lastName}, à ${currentTime}`;

    // Réponse HTTP
    return {
        statusCode: 200,
        body: JSON.stringify({ message }),
        headers: {
            "Content-Type": "application/json"
        }
    };
};
