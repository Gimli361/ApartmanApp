using ApartmanApp.Core.Enums;

namespace ApartmanApp.Business.DTOs.Ariza;

public class ArizaDetailDto
{
    public int Id { get; set; }
    public string Baslik { get; set; } = string.Empty;
    public string Aciklama { get; set; } = string.Empty;
    public ArizaDurum Durum { get; set; }
    public ArizaOncelik Oncelik { get; set; }
    public int BildirenId { get; set; }
    public string BildirenAdSoyad { get; set; } = string.Empty;
    public string BildirenDaireNo { get; set; } = string.Empty;
    public DateTime Tarih { get; set; }
    public string? BlokNo { get; set; }
    public string? RedNedeni { get; set; }
    public int TakipciSayisi { get; set; }
    public bool KullaniciTakipEdiyor { get; set; }
}
