import tkinter as tk
from tkinter import messagebox
import sqlite3

class Application(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Affichage des Informations des Fils")
        self.geometry("600x500")  # Ajustez la taille de la fenêtre si nécessaire

        # Connexion à la base de données
        self.conn = sqlite3.connect("fils.db")
        self.create_table()

        # Dictionnaire pour les couleurs réelles
        self.colors = {
            "rouge": "#FF0000",
            "vert": "#00FF00",
            "bleu": "#0000FF",
            "jaune": "#FFFF00",
            "cyan": "#00FFFF",
            "magenta": "#FF00FF",
            "orange": "#FFA500",
            "violet": "#800080",
            "rose": "#FFC0CB",
            "gris": "#808080",
            "noir": "#000000",
            "blanc": "#FFFFFF",
            "lime": "#00FF00",
            "teal": "#008080",
            "navy": "#000080",
            "marron": "#800000",
            "mauve": "#E0B0FF",
            "blanc": "#FFFFFF",
        }

        # Pagination
        self.page = 0  # Page actuelle
        self.items_per_page = 6  # Nombre d'éléments par page

        # Configuration de l'interface
        self.setup_ui()

        # Charger les fils existants depuis la base de données
        self.load_fils()

    def create_table(self):
        """Crée la table dans la base de données si elle n'existe pas."""
        cursor = self.conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS fils (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                identifiant TEXT NOT NULL,
                couleur TEXT NOT NULL,
                section REAL NOT NULL,
                longueur REAL NOT NULL
            )
        ''')
        self.conn.commit()

    def setup_ui(self):
        # Cadre pour les entrées
        frame_entrees = tk.Frame(self)
        frame_entrees.pack(pady=10)

        # Champs de saisie
        tk.Label(frame_entrees, text="Identifiant :").grid(row=0, column=0, padx=5)
        self.id_var = tk.StringVar()
        tk.Entry(frame_entrees, textvariable=self.id_var).grid(row=0, column=1)

        tk.Label(frame_entrees, text="Couleur du fil :").grid(row=1, column=0, padx=5)
        self.couleur_var = tk.StringVar()
        tk.Entry(frame_entrees, textvariable=self.couleur_var).grid(row=1, column=1)

        tk.Label(frame_entrees, text="Section du fil (mm²) :").grid(row=2, column=0, padx=5)
        self.section_var = tk.StringVar()
        tk.Entry(frame_entrees, textvariable=self.section_var).grid(row=2, column=1)

        tk.Label(frame_entrees, text="Longueur du fil (mm) :").grid(row=3, column=0, padx=5)
        self.longueur_var = tk.StringVar()
        tk.Entry(frame_entrees, textvariable=self.longueur_var).grid(row=3, column=1)

        # Cadre pour les boutons
        frame_boutons = tk.Frame(self)
        frame_boutons.pack(pady=10)

        # Boutons de navigation
        tk.Button(frame_boutons, text="Précédent", command=self.page_precedente).grid(row=0, column=0, padx=5)
        tk.Button(frame_boutons, text="Ajouter", command=self.ajouter_fil).grid(row=0, column=1, padx=5)
        tk.Button(frame_boutons, text="Supprimer", command=self.supprimer_fil).grid(row=0, column=2, padx=5)  # Nouveau bouton "Supprimer"
        tk.Button(frame_boutons, text="Suivant", command=self.page_suivante).grid(row=0, column=3, padx=5)

        # Canvas pour afficher les fils
        self.canvas = tk.Canvas(self, bg="white")
        self.canvas.pack(fill=tk.BOTH, expand=True)

    def ajouter_fil(self):
        """Ajoute un nouveau fil à la base de données et à l'affichage."""
        identifiant = self.id_var.get()
        couleur = self.couleur_var.get().lower()  # Normaliser en minuscules
        section = self.section_var.get()
        longueur = self.longueur_var.get()

        if identifiant and couleur and section and longueur:
            try:
                section = float(section)
                longueur = float(longueur)
                if section <= 0 or longueur <= 0:
                    raise ValueError

                # Enregistrer dans la base de données
                cursor = self.conn.cursor()
                cursor.execute('''
                    INSERT INTO fils (identifiant, couleur, section, longueur)
                    VALUES (?, ?, ?, ?)
                ''', (identifiant, couleur, section, longueur))
                self.conn.commit()

                self.clear_entries()
                messagebox.showinfo("Succès", "Fil ajouté avec succès!")
                self.load_fils()  # Rafraîchir l'affichage après ajout
            except ValueError:
                messagebox.showerror("Erreur", "Veuillez entrer des valeurs numériques valides pour la section et la longueur.")
        else:
            messagebox.showerror("Erreur", "Veuillez remplir tous les champs.")

    def supprimer_fil(self):
        """Supprime un fil de la base de données en fonction de l'identifiant fourni."""
        identifiant = self.id_var.get()

        if identifiant:
            cursor = self.conn.cursor()
            cursor.execute('''
                DELETE FROM fils WHERE identifiant = ?
            ''', (identifiant,))
            if cursor.rowcount == 0:
                messagebox.showerror("Erreur", "Aucun fil trouvé avec cet identifiant.")
            else:
                self.conn.commit()
                messagebox.showinfo("Succès", "Fil supprimé avec succès!")
                self.clear_entries()
                self.load_fils()  # Rafraîchir l'affichage après suppression
        else:
            messagebox.showerror("Erreur", "Veuillez entrer un identifiant pour supprimer un fil.")

    def afficher_fils(self):
        """Affiche les fils de la page actuelle dans le canvas."""
        # Effacer le canvas
        self.canvas.delete("all")

        # Récupérer les fils depuis la base de données
        cursor = self.conn.cursor()
        cursor.execute(f"SELECT identifiant, couleur, section, longueur FROM fils LIMIT {self.items_per_page} OFFSET {self.page * self.items_per_page}")
        fils = cursor.fetchall()

        # Calculer la hauteur de chaque ligne
        height = 40
        y_position = 10  # Position y pour dessiner

        # Ajouter les fils au canvas
        for fil in fils:
            identifiant, couleur, section, longueur = fil
            couleurs_list = [c.strip() for c in couleur.split('-')]  # Séparer les couleurs par '-'

            # Prendre deux couleurs pour la moitié
            if len(couleurs_list) == 2:
                couleur1 = self.colors.get(couleurs_list[0], "#FFFFFF")
                couleur2 = self.colors.get(couleurs_list[1], "#FFFFFF")

                # Dessiner un rectangle avec deux couleurs
                self.canvas.create_rectangle(10, y_position, 300, y_position + height, fill=couleur1, outline="")
                self.canvas.create_rectangle(300, y_position, 590, y_position + height, fill=couleur2, outline="")
            else:
                couleur_principale = self.colors.get(couleurs_list[0], "#FFFFFF")
                self.canvas.create_rectangle(10, y_position, 590, y_position + height, fill=couleur_principale, outline="")

            # Déterminer la couleur du texte en fonction de la couleur du fil
            text_color = "black"  # Couleur par défaut
            if "noir" in couleurs_list:
                text_color = "white"  # Changer en blanc si la couleur est noire

            # Ajouter du texte pour afficher les informations
            self.canvas.create_text(300, y_position + height / 2, text=f"{identifiant} - {couleur} - {section} mm² - {longueur} mm", fill=text_color)

            # Déplacer vers la prochaine ligne
            y_position += height + 5

    def load_fils(self):
        """Charge tous les fils depuis la base de données au démarrage."""
        self.afficher_fils()

    def page_suivante(self):
        """Change vers la page suivante et affiche les fils correspondants."""
        cursor = self.conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM fils")
        total_fils = cursor.fetchone()[0]
        if (self.page + 1) * self.items_per_page < total_fils:
            self.page += 1
            self.afficher_fils()

    def page_precedente(self):
        """Change vers la page précédente et affiche les fils correspondants."""
        if self.page > 0:
            self.page -= 1
            self.afficher_fils()

    def clear_entries(self):
        """Réinitialise les champs de saisie."""
        self.id_var.set("")
        self.couleur_var.set("")
        self.section_var.set("")
        self.longueur_var.set("")

    def on_closing(self):
        """Ferme la connexion à la base de données avant de quitter l'application."""
        self.conn.close()
        self.destroy()

if __name__ == "__main__":
    app = Application()
    app.protocol("WM_DELETE_WINDOW", app.on_closing)  # Assurez-vous de fermer la connexion
    app.mainloop()
