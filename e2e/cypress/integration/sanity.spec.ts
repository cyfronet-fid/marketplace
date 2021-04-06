describe('TypeScript', () => {
    it('sanity', () => {
        cy.visit('/');
        cy.get('.autocomplete-input').first().type("test");
        cy.get('.intro-box').first().find('a').should("exist");
        cy.location('pathname').should('be.eq', "/");
    })
})