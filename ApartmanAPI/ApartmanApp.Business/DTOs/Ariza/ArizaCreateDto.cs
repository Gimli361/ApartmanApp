using ApartmanApp.Core.Enums;

namespace ApartmanApp.Business.DTOs.Ariza;

public class ArizaCreateDto
{
    public string Baslik { get; set; } = string.Empty;
    public string Aciklama { get; set; } = string.Empty;
    public ArizaOncelik Oncelik { get; set; } = ArizaOncelik.Orta;
    public int BildirenId { get; set; }
}
