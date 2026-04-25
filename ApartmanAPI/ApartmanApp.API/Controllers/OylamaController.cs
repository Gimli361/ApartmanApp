using System.Security.Claims;
using ApartmanApp.Business.DTOs.Oylama;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Validators;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OylamaController(IOylamaService oylamaService) : ControllerBase
{
    private bool TryGetCurrentUserId(out int id) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out id) && id > 0;

    /// Tüm oylamalar (aktif+pasif)
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await oylamaService.GetAllAsync(currentUserId);
        return Ok(result);
    }

    /// Oylama detayı — seçenekler ve oy oranları
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await oylamaService.GetByIdAsync(id, currentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Yeni oylama oluştur (sadece admin)
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] OylamaCreateDto dto)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();

        var validation = await new OylamaCreateValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await oylamaService.CreateAsync(dto, currentUserId);
        if (!result.Success)
            return BadRequest(result);
        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    /// Oy ver
    [HttpPost("{id:int}/oy")]
    public async Task<IActionResult> OyVer(int id, [FromBody] OyVerDto dto)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await oylamaService.OyVerAsync(id, dto.SecenekId, currentUserId);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Oy geri al
    [HttpDelete("{id:int}/oy")]
    public async Task<IActionResult> OyGeriAl(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await oylamaService.OyGeriAlAsync(id, currentUserId);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Aktif/pasif geçiş (sadece admin)
    [HttpPatch("{id:int}/toggle")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Toggle(int id)
    {
        var result = await oylamaService.ToggleAktifAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Oylama sil (sadece admin)
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await oylamaService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}
