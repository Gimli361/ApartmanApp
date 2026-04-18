namespace ApartmanApp.Business.DTOs.Bina;

public class BlokDetayDto
{
    public int Id { get; set; }
    public string Ad { get; set; } = string.Empty;
    public List<DaireDetayDto> Daireler { get; set; } = [];
}

public class DaireDetayDto
{
    public int Id { get; set; }
    public string DaireNo { get; set; } = string.Empty;
    public SakinOzetDto? Sakin { get; set; }
}

public class SakinOzetDto
{
    public int Id { get; set; }
    public string AdSoyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
}
