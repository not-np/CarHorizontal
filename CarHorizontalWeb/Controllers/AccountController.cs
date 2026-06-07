using System;
using System.Data.Entity.Migrations.Model;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using CarHorizontalWeb.Models; // ovo povezuje kontroler sa entity framework modelima iz moje baze

namespace CarHorizontalWeb.Controllers
{
    public class AccountController : Controller
    {
        // odje se pravi objekat baze preko kojega se sva logika sa podacima radi
        private CarHorizontalBaza db = new CarHorizontalBaza();

        //registracija ovo httpget prikazuje stranicu
        [HttpGet]
        public ActionResult Register()
        {
            
            return View();
        }

        //obrada podataka i registracija
        [HttpPost]
        public ActionResult Register(string ime, string prezime, string email, string lozinka, string telefon, string grad, string drzava)
        {
            //provjera da li u tabeli vec postoji unijeti email
            if (db.Korisnicis.Any(k => k.Email == email))
            {
                //error klasicni ako postoji
                ViewBag.Greska = "Korisnik sa ovim Email-om već postoji!";
                return View();
            }

            try
            {
                // trazenje linije uloge iz istoimene tabele
                var ulogaKorisnik = db.Uloges.FirstOrDefault(u => u.NazivUloge == "Korisnik");

                // if nadjen uzimas njen broj ako ne postavljas na 2 ssto je korisnik
                int ulogaId = ulogaKorisnik != null ? ulogaKorisnik.UlogaID : 2;

                // pravi se objekat klase korisnici i mapira se u sql tabeli 
                Korisnici noviKorisnik = new Korisnici
                {
                    Ime = ime,
                    Prezime = prezime,
                    Email = email,
                    Lozinka = lozinka, 
                    UlogaID = ulogaId,
                    DatumRegistracije = DateTime.Now 
                };

                //dodaje se novi objekat u ef memory
                db.Korisnicis.Add(noviKorisnik);

                // guraju se podaci u sql,server sam generise novi korisnikid
                db.SaveChanges();

                // \pravljenje profila za korisnika
                ProfiliKorisnika noviProfil = new ProfiliKorisnika
                {
                    //onaj prethodni generisani korisnikid se koristi
                    KorisnikID = noviKorisnik.KorisnikID,
                    BrojTelefona = telefon,
                    Grad = grad,
                    Drzava = drzava
                };

                // pusha se u bazu profil
                db.ProfiliKorisnikas.Add(noviProfil);
                db.SaveChanges();

                
                return RedirectToAction("Login");
            }
            catch (Exception ex)
            {
                //greska za sql klasicna(ako nesto pukne u njemu)
                ViewBag.Greska = "Sistemska greška pri registraciji: " + ex.Message;
                return View();
            }
        }

        

        [HttpGet]
        public ActionResult Login()
        {
            return View();
        }

        //logovanje obrada podataka cijela logika toga
        [HttpPost]
        public ActionResult Login(string email, string lozinka)
        {
            //trazi se korisnik u bazi ciji se email poklapa sa unijetim
            var korisnik = db.Korisnicis.FirstOrDefault(k => k.Email == email && k.Lozinka == lozinka);

            //ako je pronadjen (nije null)
            if (korisnik != null)
            {
                //otvaranje sesije sesija pamti sve o trenutnom ulogovanom korisniku
                Session["KorisnikID"] = korisnik.KorisnikID;
                Session["ImePrezime"] = korisnik.Ime + " " + korisnik.Prezime;
                Session["Uloga"] = korisnik.Uloge.NazivUloge; //cuvanje da li je admin ili korisnik

                //samo se vrati na pocetnu stranicu sajta nakon logovanja
                return RedirectToAction("Index", "Home");
            }

            //javljamo grešku ako ne postoji korisnik
            ViewBag.Greska = "Pogrešan email ili lozinka!";
            return View();
        }

        //logout
        public ActionResult Logout()
        {
            //session ckear brise sve podatke o ulogovanom korisniku (sign out)
            Session.Clear();

            //pocetna kao gost
            return RedirectToAction("Index", "Home");
        }
    }
}