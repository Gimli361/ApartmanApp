using System.Security.Claims;
using ApartmanApp.Business.DTOs.Bildirim;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Validators;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BildirimController(IBildirimService bildirimService) : ControllerBase
{
    private bool TryGetCurrentUserId(out int id) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out id) && id > 0;

    /// Oturumdaki kullanıcının bildirimleri
    [HttpGet]
    public async Task<IActionResult> GetMyBildirimler()
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await bildirimService.GetByKullaniciIdAsync(currentUserId);
        return Ok(result);
    }

    /// Sayfalı bildirim listesi
    [HttpGet("paged")]
    public async Task<IActionResult> GetMyBildirimlerPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await bildirimService.GetPagedByKullaniciIdAsync(currentUserId, page, pageSize);
        return Ok(result);
    }

    /// Okunmamış bildirim sayısı
    [HttpGet("okunmamis-sayi")]
    public async Task<IActionResult> GetUnreadCount()
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var count = await bildirimService.GetUnreadCountAsync(currentUserId);
        return Ok(new { count });
    }

    /// Tüm bildirimleri okundu olarak işaretle
    [HttpPatch("tumu-okundu")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await bildirimService.MarkAllAsReadAsync(currentUserId);
        return Ok(result);
    }

    /// Bildirimi okundu olarak işaretle
    [HttpPatch("{id:int}/okundu")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await bildirimService.MarkAsReadAsync(id, currentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Tüm sakinlere genel duyuru (sadece admin)
    [HttpPost("duyuru")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendDuyuru([FromBody] DuyuruCreateDto dto)
    {
        var validation = await new DuyuruCreateValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        await bildirimService.SendToAllSakinlerAsync(dto.Baslik, dto.Icerik);
        return Ok(new { message = "Duyuru tüm sakinlere gönderildi." });
    }

    /// Belirli bir bloğa bildirim (sadece admin)
    [HttpPost("blok")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendToBlok([FromBody] BlokBildirimDto dto)
    {
        var validation = await new BlokBildirimValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        await bildirimService.SendToBlokAsync(dto.BlokNo, dto.Baslik, dto.Icerik);
        return Ok(new { message = $"{dto.BlokNo} bloğundaki tüm sakinlere bildirim gönderildi." });
    }

    /// Belirli bir daireye bildirim (sadece admin)
    [HttpPost("daire")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SendToDaire([FromBody] DaireBildirimDto dto)
    {
        var validation = await new DaireBildirimValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        await bildirimService.SendToDaireAsync(dto.DaireNo, dto.Baslik, dto.Icerik, dto.BlokNo);
        var hedef = string.IsNullOrWhiteSpace(dto.BlokNo)
            ? dto.DaireNo
            : $"{dto.BlokNo} Blok {dto.DaireNo}";
        return Ok(new { message = $"{hedef} dairesine bildirim gönderildi." });
    }
}
