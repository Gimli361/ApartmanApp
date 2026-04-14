using System.Security.Claims;
using ApartmanApp.Business.DTOs.Bildirim;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BildirimController(IBildirimService bildirimService) : ControllerBase
{
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// Oturumdaki kullanıcının bildirimleri
    [HttpGet]
    public async Task<IActionResult> GetMyBildirimler()
    {
        var result = await bildirimService.GetByKullaniciIdAsync(CurrentUserId);
        return Ok(result);
    }

    /// Okunmamış bildirim sayısı
    [HttpGet("okunmamis-sayi")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var count = await bildirimService.GetUnreadCountAsync(CurrentUserId);
        return Ok(new { count });
    }

    /// Bildirimi okundu olarak işaretle
    [HttpPatch("{id:int}/okundu")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var result = await bildirimService.MarkAsReadAsync(id, CurrentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Tüm sakinlere genel duyuru (sadece admin)
    [HttpPost("duyuru")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendDuyuru([FromBody] DuyuruCreateDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Baslik) || string.IsNullOrWhiteSpace(dto.Icerik))
            return BadRequest("Başlık ve içerik zorunludur.");

        await bildirimService.SendToAllSakinlerAsync(dto.Baslik, dto.Icerik);
        return Ok(new { message = "Duyuru tüm sakinlere gönderildi." });
    }

    /// Belirli bir daireye bildirim (sadece admin)
    [HttpPost("daire")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendToDaire([FromBody] DaireBildirimDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.DaireNo) || string.IsNullOrWhiteSpace(dto.Baslik))
            return BadRequest("Daire No, başlık ve içerik zorunludur.");

        await bildirimService.SendToDaireAsync(dto.DaireNo, dto.Baslik, dto.Icerik);
        return Ok(new { message = $"{dto.DaireNo} dairesine bildirim gönderildi." });
    }
}
