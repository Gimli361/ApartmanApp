using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BlokController(IBlokService blokService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await blokService.GetAllAsync();
        return Ok(result);
    }

    [HttpGet("detay")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllWithSakinler()
    {
        var result = await blokService.GetAllWithSakinlerAsync();
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] BlokCreateRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Ad))
            return BadRequest("Blok adı zorunludur.");

        var result = await blokService.CreateAsync(request.Ad);
        if (!result.Success)
            return BadRequest(result);

        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await blokService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);

        return Ok(result);
    }
}

public record BlokCreateRequest(string Ad);
