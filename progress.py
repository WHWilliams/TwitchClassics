import tkinter as tk
from tkinter import ttk
import sqlite3

db_filename = 'usr.db'

conn = sqlite3.connect(db_filename)

cc = conn.cursor()
print(cc.execute("SELECT * FROM user").fetchall())

def handleMarioKiller(killerName):
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM user WHERE name=?",[(killerName)])
    userData = cursor.fetchone()
    print(userData)
    if userData is not None:
        print('incrementing')
        cursor.execute("UPDATE user SET marioKills=marioKills + 1 WHERE usr_number=?",[(userData[0])])    
        return
    print('inserting')
    cursor.execute("INSERT INTO user VALUES (null,?,1,0,0)",[(killerName)])
    

def handleKillers():
    with open('killers') as f:
        for line in f:
            handleMarioKiller(line.strip('\n'))

    with open('killers','w+') as f:
        f.write('')

    
class SampleApp(tk.Tk):

    def __init__(self, *args, **kwargs):
        tk.Tk.__init__(self, *args, **kwargs)

        self.s = ttk.Style()
        self.s.theme_use('clam')
        self.s.configure("red.Vertical.TProgressbar", foreground='black', background='black')

        self.progress = ttk.Progressbar(self, orient="vertical", style="red.Vertical.TProgressbar",
                                        length=150, mode="determinate")
        self.progress.place(x=385,y=20)
        self.progress["maximum"] = 100

        self.T1 = ttk.Label(self,text="none", background="red")
        self.T1.place(x=0,y=20)

        self.T2 = ttk.Label(self,text="none", background="green")
        self.T2.place(x=0,y=60)

        self.T3 = ttk.Label(self,text="none", background="blue")
        self.T3.place(x=0,y=100)
        

        self.readProgress()

    def readProgress(self):
        handleKillers()
        file = open("data")
        self.T1["text"] = file.readline().replace("\n","")
        self.T2["text"] = file.readline().replace("\n","")
        self.T3["text"] = file.readline().replace("\n","")
        try:
            q = int(file.readline())
            self.progress["value"] = q
        except:
            self.progress["value"] = self.progress["value"]           
        file.close()
        self.after(500, self.readProgress)

app = SampleApp()
app.geometry("427x240")
app.configure(background='black')
app.mainloop()
