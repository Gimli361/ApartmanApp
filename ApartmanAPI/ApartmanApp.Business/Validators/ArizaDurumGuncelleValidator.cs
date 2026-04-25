using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Core.Enums;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class ArizaDurumGuncelleValidator : AbstractValidator<ArizaDurumGuncelleDto>
{
    public ArizaDurumGuncelleValidator()
    {
        RuleFor(x => x.Durum)
            .IsInEnum().WithMessage("Geçersiz durum değeri.");

        // Reddedildi seçilirse RedNedeni zorunlu
        RuleFor(x => x.RedNedeni)
            .NotEmpty().WithMessage("Red nedeni zorunludur.")
            .MaximumLength(500).WithMessage("Red nedeni en fazla 500 karakter olabilir.")
            .When(x => x.Durum == ArizaDurum.Reddedildi);
    }
}
