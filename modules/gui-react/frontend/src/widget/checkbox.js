import PropTypes from 'prop-types'
import React from 'react'
import styles from './checkbox.module.css'

const Checkbox = ({label, input, tabIndex, className, onChange}) =>
    <label className={[styles.container, input.errorClass, className].join(' ')}>
        <input
            type='checkbox'
            name={input.name}
            checked={!!input.value}
            tabIndex={tabIndex}
            onChange={(e) => {
                input.handleChange(e)
                input.validate()
                onChange && onChange(!!e.target.checked)
            }}
        />
        <span className={styles.checkbox}/>
        {label}
    </label>

Checkbox.propTypes = {
    label: PropTypes.string.isRequired,
    input: PropTypes.object.isRequired,
    tabIndex: PropTypes.number,
    className: PropTypes.string,
    onChange: PropTypes.func
}

export default Checkbox