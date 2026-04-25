using System.Security.Claims;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/ariza")]
[Authorize]
public class ArizaTakipController(IArizaTakipService takipService) : ControllerBase
{
    private bool TryGetCurrentUserId(out int id) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out id) && id > 0;

    /// Arızayı takibe al
    [HttpPost("{id:int}/takip")]
    public async Task<IActionResult> TakipEt(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await takipService.TakipEtAsync(id, currentUserId);
        return Ok(result);
    }

    /// Arıza takibinden çık
    [HttpDelete("{id:int}/takip")]
    public async Task<IActionResult> TakiptenCik(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var result = await takipService.TakiptenCikAsync(id, currentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Arıza takip durumu (takip ediyor mu + takipçi sayısı)
    [HttpGet("{id:int}/takip-durumu")]
    public async Task<IActionResult> GetTakipDurumu(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId)) return Unauthorized();
        var dto = await takipService.GetTakipDurumuAsync(id, currentUserId);
        return Ok(dto);
    }

}
