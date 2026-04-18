namespace ApartmanWeb.Models;

public class SakinOzetDto
{
    public int Id { get; set; }
    public string AdSoyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
}

public class DaireDto
{
    public int Id { get; set; }
    public string DaireNo { get; set; } = string.Empty;
    public SakinOzetDto? Sakin { get; set; }
}

public class BlokDto
{
    public int Id { get; set; }
    public string Ad { get; set; } = string.Empty;
    public List<DaireDto> Daireler { get; set; } = new();
}

public class BlokEkleRequest
{
    public string Ad { get; set; } = string.Empty;
}

public class DaireEkleRequest
{
    public int BlokId { get; set; }
    public string DaireNo { get; set; } = string.Empty;
}
